# Deploying an App to the Droplet

Complete guide for deploying a containerized app behind Caddy on the droplet. Each app gets its own compose file under `/opt/apps/<app>/` and a Caddy site snippet for routing.

## 1. Prerequisites

Before deploying an app, you need:

- **Droplet running** — provisioned via `terraform apply` (see README)
- **SSH access** — you can SSH into the droplet as `akash`
- **Container image** — your app image is pushed to GHCR (or another registry)
- **Wildcard DNS** — already configured by Terraform (`*.example.com`)

## 2. What your app repo needs

- `Dockerfile` — builds your app image
- `.github/workflows/deploy.yml` — GitHub Actions workflow (template below)
- **Repository secrets** — SSH key and droplet connection details

## 3. Droplet layout

```
/opt/caddy/                  # Platform (managed by cloud-init)
├── Caddyfile                # Main Caddy config
├── docker-compose.yml       # Caddy service only
├── .env                     # DO token for DNS-01
├── site/index.html          # Static landing page
└── sites/                   # App Caddy snippets (*.caddy)
    └── myapp.caddy          # ← deployed by app pipeline

/opt/apps/                   # App deployments (one dir per app)
└── myapp/
    └── docker-compose.yml   # ← deployed by app pipeline
```

Platform files under `/opt/caddy/` are managed by Terraform/cloud-init. App pipelines only write to `/opt/apps/<app>/` and `/opt/caddy/sites/<app>.caddy`.

## 4. SSH access setup

Each app repo needs a deploy key to SSH into the droplet.

1. Generate a key pair (on your local machine):

   ```bash
   ssh-keygen -t ed25519 -f deploy_key_myapp -C "deploy-myapp" -N ""
   ```

2. Add the **public** key to the droplet:

   ```bash
   ssh akash@<droplet-ip> 'cat >> ~/.ssh/authorized_keys' < deploy_key_myapp.pub
   ```

3. Add the **private** key as a repository secret named `DROPLET_SSH_KEY` in your app's GitHub repo.

4. Add these additional repository secrets:

   | Secret | Value |
   |---|---|
   | `DROPLET_HOST` | Droplet IPv4 address |
   | `DROPLET_USER` | `akash` |

## 5. Caddy snippet template

Create `<app>.caddy` with your app's subdomain and internal port:

```caddy
<app>.example.com {
    encode zstd gzip
    header {
        Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Content-Security-Policy "default-src 'self';"
    }
    reverse_proxy <app>:<internal-port>
    log {
        output file /var/log/caddy/<app>.access.log
        format json
    }
}
```

Replace `<app>`, `example.com`, and `<internal-port>` with your values.

## 6. docker-compose.yml template

Each app gets its own compose file at `/opt/apps/<app>/docker-compose.yml`:

```yaml
services:
  <app>:
    image: ghcr.io/<org>/<app>:<tag>
    container_name: <app>
    restart: unless-stopped
    networks:
      - proxy
    environment:
      APP_LOG_LEVEL: info

networks:
  proxy:
    external: true
```

Key points:
- The `proxy` network is declared as `external: true` — it's created by the platform's Caddy compose file
- The container name must match what the Caddy snippet uses in `reverse_proxy`

## 7. GitHub Actions workflow template

Copy this to `.github/workflows/deploy.yml` in your app repo and replace the placeholders:

| Placeholder | Example | Description |
|---|---|---|
| `<app>` | `vocab` | Short app name |
| `<org>` | `aceakash` | GitHub org/user |
| `<internal-port>` | `8080` | Port the container listens on |
| `example.com` | `example.com` | Your domain |

```yaml
name: Deploy <app>

on:
  push:
    branches: [main]
    paths:
      - "Dockerfile"
      - "src/**"
  workflow_dispatch:

env:
  IMAGE: ghcr.io/<org>/<app>

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

      - name: Build and push
        run: |
          docker build -t $IMAGE:${{ github.sha }} -t $IMAGE:latest .
          docker push $IMAGE:${{ github.sha }}
          docker push $IMAGE:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    concurrency: <app>-deploy
    steps:
      - name: Deploy to droplet
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.DROPLET_HOST }}
          username: ${{ secrets.DROPLET_USER }}
          key: ${{ secrets.DROPLET_SSH_KEY }}
          script: |
            set -e

            # Create app directory
            sudo mkdir -p /opt/apps/<app>
            sudo mkdir -p /opt/caddy/sites

            # Write docker-compose.yml
            sudo tee /opt/apps/<app>/docker-compose.yml > /dev/null <<'COMPOSE'
            services:
              <app>:
                image: ghcr.io/<org>/<app>:latest
                container_name: <app>
                restart: unless-stopped
                networks:
                  - proxy
                environment:
                  APP_LOG_LEVEL: info

            networks:
              proxy:
                external: true
            COMPOSE

            # Write Caddy site snippet
            sudo tee /opt/caddy/sites/<app>.caddy > /dev/null <<'CADDY'
            <app>.example.com {
                encode zstd gzip
                header {
                    Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
                    X-Content-Type-Options "nosniff"
                    X-Frame-Options "DENY"
                    Referrer-Policy "strict-origin-when-cross-origin"
                    Content-Security-Policy "default-src 'self';"
                }
                reverse_proxy <app>:<internal-port>
                log {
                    output file /var/log/caddy/<app>.access.log
                    format json
                }
            }
            CADDY

            # Pull and start the app
            sudo docker compose -f /opt/apps/<app>/docker-compose.yml pull
            sudo docker compose -f /opt/apps/<app>/docker-compose.yml up -d

            # Reload Caddy to pick up the new site snippet
            sudo docker compose -f /opt/caddy/docker-compose.yml exec caddy caddy reload --config /etc/caddy/Caddyfile

            # Health check
            sleep 5
            curl -fsS https://<app>.example.com/health || echo "Health check failed — verify manually."
```

## 8. Health check

- Your app should expose a `/health` endpoint returning HTTP 200.
- The workflow does a basic `curl` check after deploy. For production, add retries:

  ```bash
  for i in 1 2 3 4 5; do
    curl -fsS https://<app>.example.com/health && break
    sleep 5
  done
  ```

## 9. Rollback

To roll back to a previous version:

1. Update the image tag in `/opt/apps/<app>/docker-compose.yml` to the previous SHA or version.
2. Pull and restart:

   ```bash
   sudo docker compose -f /opt/apps/<app>/docker-compose.yml pull
   sudo docker compose -f /opt/apps/<app>/docker-compose.yml up -d
   ```

Or re-run the GitHub Actions workflow for the previous commit.

## 10. Removing an app

1. Stop and remove the container:

   ```bash
   sudo docker compose -f /opt/apps/<app>/docker-compose.yml down
   ```

2. Remove the Caddy snippet and reload:

   ```bash
   sudo rm /opt/caddy/sites/<app>.caddy
   sudo docker compose -f /opt/caddy/docker-compose.yml exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

3. Clean up the app directory:

   ```bash
   sudo rm -rf /opt/apps/<app>
   ```
