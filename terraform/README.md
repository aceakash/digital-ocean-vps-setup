# Terraform layout

This folder contains a minimal, repeatable Terraform layout to provision a DigitalOcean droplet and baseline resources according to the project's functional requirements.

Quickstart

0. Create a digital ocean token (API key) with the following scopes:

- droplet:all
- domain:all
- ssh_key:all
- tag:all
- firewall:all

1. Export your DigitalOcean token and ensure you have a public SSH key at `~/.ssh/id_rsa.pub` (or override via `ssh_public_key_path`).

   ```bash
   export DIGITALOCEAN_TOKEN="<token>"
   terraform init
   terraform plan -var="ssh_public_key_path=$HOME/.ssh/iuntilfalse_id_rsa.pub" -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
   terraform apply -var="ssh_public_key_path=$HOME/.ssh/iuntilfalse_id_rsa.pub" -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
   ```

Notes

- `cloud-init.yaml` sets up user `akash`, installs Docker & compose plugin, enables `fail2ban` and `unattended-upgrades`, configures UFW (22/80/443), and writes a Docker `daemon.json` to configure json-file log rotation.
- It also writes Caddy assets under `/opt/caddy/` (`Caddyfile`, `docker-compose.yml`, static `index.html`), plus helper script `/usr/local/bin/caddy-compose-up.sh` and systemd unit `caddy-compose.service`.
- Terraform state is local by default; add remote state when appropriate.

## Caddy static site

On first boot, systemd runs the oneshot unit to start the Caddy container (serving `untilfalse.com` and `www.untilfalse.com`). TLS certificates (including wildcard) are retrieved via DNS-01 using the DigitalOcean token.

Check status:

```bash
docker ps | grep caddy
docker logs caddy | head -n 50
```

## Token rotation

Replace token in `/opt/caddy/.env` then restart:

```bash
sudo sed -i "s/^DIGITALOCEAN_TOKEN=.*/DIGITALOCEAN_TOKEN=<new_token>/" /opt/caddy/.env
docker compose -f /opt/caddy/docker-compose.yml restart caddy
```

Force renewal (optional):

```bash
docker exec caddy caddy renew --force
```

## Improve secret hygiene (recommended)

Remove token from user_data (stop passing it into the template), create `/opt/caddy/.env` manually post-provision, then rerun:

```bash
systemctl restart caddy-compose.service
```

## Remote state next

Add `backend.tf` with Terraform Cloud or S3 + DynamoDB locking for collaboration and drift prevention.

## External apps (future)

External app repos will join Docker network `proxy`, drop a Caddy snippet into `/opt/caddy/sites-enabled/`, and trigger:

```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## Safety

User data (cloud-init) is visible via provider APIs; avoid embedding long-lived secrets there.
