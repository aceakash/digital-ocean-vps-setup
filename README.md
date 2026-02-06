# DigitalOcean VPS Setup

Terraform configuration that provisions a single DigitalOcean droplet running containerized web apps behind Caddy with wildcard TLS (DNS-01).

## What gets provisioned

- **Droplet** — Ubuntu 24.04, hardened via cloud-init (non-root user, fail2ban, UFW, unattended upgrades, Docker + Compose)
- **DNS** — A record for the apex domain + wildcard record (e.g. `*.example.com`)
- **Firewall** — inbound 22, 80, 443 only
- **Caddy** — reverse proxy with automatic wildcard certs, serving a static landing page and the vocab app
- **Systemd unit** — `caddy-compose.service` starts the Docker Compose stack on boot

Cloud-init is idempotent. All Caddy assets live under `/opt/caddy/` on the droplet.

## Required inputs

You must provide these two variables (everything else has sensible defaults — see `terraform/variables.tf`):

- `digitalocean_token` — DO API token with DNS write + droplet create permissions (sensitive)
- `domain` — apex domain to create records for (e.g. `example.com`)

## Quickstart

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your token and domain

terraform init
terraform plan
terraform apply
```

Or pass variables directly:

```bash
export DIGITALOCEAN_TOKEN="<token>"
terraform plan \
  -var="digitalocean_token=$DIGITALOCEAN_TOKEN" \
  -var="domain=example.com"
```

**Important:** Changing `cloud-init.yaml` or any input that affects user_data will replace the droplet, destroying all runtime state (Docker volumes, certificates, manually-added apps).

### After apply

Cloud-init takes 3-5 minutes to finish after the droplet is created. Wait for it to complete before checking the site:

```bash
IP=$(terraform output -raw droplet_ip)
ssh akash@$IP cloud-init status --wait
```

Once cloud-init finishes, verify the site:

```bash
curl -I https://example.com
```

If something goes wrong, check cloud-init logs:

```bash
ssh akash@$IP sudo cat /var/log/cloud-init-output.log
```

## Validating changes

```bash
cd terraform
terraform fmt -check -recursive
terraform init -input=false -backend=false
terraform validate
```

This is what CI runs on every push/PR touching `terraform/`.

## On the droplet

Check Caddy is running:

```bash
docker ps | grep caddy
docker logs caddy | head -n 50
```

### Token rotation

```bash
sudo sed -i "s/^DIGITALOCEAN_TOKEN=.*/DIGITALOCEAN_TOKEN=<new_token>/" /opt/caddy/.env
docker compose -f /opt/caddy/docker-compose.yml restart caddy
# Optional: force certificate renewal
docker exec caddy caddy renew --force
```

## Destroy

```bash
cd terraform
terraform destroy \
  -var="digitalocean_token=$DIGITALOCEAN_TOKEN" \
  -var="domain=example.com"
```

## Adding a new app

Wildcard DNS is already in place, so new subdomains don't require Terraform changes. To deploy a new app:

1. Add a service to `/opt/caddy/docker-compose.yml` on the `proxy` network
2. Add a Caddy site snippet to `/opt/caddy/sites/<app>.caddy`
3. `docker compose pull <app> && docker compose up -d <app>`
4. Reload Caddy: `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`

See `cicd.md` for the full GitHub Actions deployment pattern.
