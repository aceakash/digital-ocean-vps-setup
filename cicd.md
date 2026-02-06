# GitHub Actions Deployment Pattern

Reusable CI/CD pattern for deploying a containerized app behind Caddy on the droplet. Copy this to your app repo and substitute placeholders.

## Placeholders

| Placeholder | Example | Description |
|---|---|---|
| `<app>` | `vocab` | Short app name (used in service, file names) |
| `<app>.example.com` | `vocab.example.com` | Subdomain |
| `<org>/<app>` | `aceakash/vocab` | GHCR image path |
| `<version>` | `0.1.0` | Semver tag |
| `<internal-port>` | `8080` | Port the container listens on |

## Goals

- Build & push image to GHCR.
- Upload Caddy site snippet for the subdomain.
- Ensure service exists in docker-compose.
- Pull and run updated container.
- Reload Caddy for new routing.
- Keep process idempotent.

## Required Repository Secrets

- `DROPLET_HOST` — Droplet IPv4.
- `DROPLET_USER` — `akash`
- `DROPLET_SSH_KEY` — Private key (PEM). Use a deploy key with least privilege.
- `GHCR_PAT` — Personal access token with `read:packages` (and `write:packages` if building here).

## Caddy Site Snippet (`/opt/caddy/sites/<app>.caddy`)

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

## docker-compose.yml Service Block (append if missing)

```yaml
<app>:
  image: ghcr.io/<org>/<app>:<version>
  container_name: <app>
  restart: unless-stopped
  networks:
    - proxy
  environment:
    APP_LOG_LEVEL: info
  labels:
    com.centurylinklabs.watchtower.enable: "true"
```

## Example Workflow (app repo)

```yaml
name: Deploy <app>

on:
  push:
    branches: [main]
    paths:
      - "Dockerfile"
      - "src/**"
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Login GHCR
        run: echo "${{ secrets.GHCR_PAT }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
      - name: Set tags
        run: |
          echo "IMAGE_SHA=ghcr.io/<org>/<app>:${{ github.sha }}" >> $GITHUB_ENV
          echo "IMAGE_SEMVER=ghcr.io/<org>/<app>:<version>" >> $GITHUB_ENV
      - name: Build
        run: docker build -t $IMAGE_SHA -t $IMAGE_SEMVER .
      - name: Push
        run: |
          docker push $IMAGE_SHA
          docker push $IMAGE_SEMVER

  deploy:
    needs: build
    runs-on: ubuntu-latest
    concurrency: <app>-deploy
    steps:
      - name: Generate site snippet
        run: |
          cat > <app>.caddy <<'EOF'
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
          EOF
      - name: Upload site file
        uses: appleboy/scp-action@v0.2.4
        with:
          host: ${{ secrets.DROPLET_HOST }}
          username: ${{ secrets.DROPLET_USER }}
          key: ${{ secrets.DROPLET_SSH_KEY }}
          source: "<app>.caddy"
          target: "/opt/caddy/sites/"
      - name: Remote deploy
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.DROPLET_HOST }}
          username: ${{ secrets.DROPLET_USER }}
          key: ${{ secrets.DROPLET_SSH_KEY }}
          script: |
            set -e
            cd /opt/caddy
            sudo mkdir -p sites
            # Ensure import directive exists
            grep -q '/opt/caddy/sites/*.caddy' Caddyfile || echo 'import /opt/caddy/sites/*.caddy' | sudo tee -a Caddyfile
            # Add service if missing
            if ! grep -q '^<app>:' docker-compose.yml; then
              sudo tee -a docker-compose.yml >/dev/null <<'YML'
              <app>:
                image: ghcr.io/<org>/<app>:<version>
                container_name: <app>
                restart: unless-stopped
                networks:
                  - proxy
                environment:
                  APP_LOG_LEVEL: info
                labels:
                  com.centurylinklabs.watchtower.enable: "true"
              YML
            fi
            sudo docker compose pull <app> || true
            sudo docker compose up -d <app>
            sudo docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile || sudo docker compose restart caddy
            curl -fsS https://<app>.example.com/health || echo "Health endpoint failed."
```

## Health Check

- Prefer `/health` returning 200.
- Extend workflow to fail job if curl returns non-zero after retries.

## Rollback

- Re-run deploy with previous semver tag.
- To remove route: delete `<app>.caddy` and reload Caddy.
- To remove container: `docker compose rm -f <app>`.

## Future Enhancements

- Add Watchtower notifications.
- Add structured log shipping.
- Pin digest tags (`image@sha256:...`).
- Use caddy-docker-proxy to eliminate manual file writes (requires base change).
