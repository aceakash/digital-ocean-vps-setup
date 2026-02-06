# Terraform layout

This folder contains a minimal, repeatable Terraform layout to provision a DigitalOcean droplet and baseline resources according to the project's functional requirements[.github/functional-requirements.md].

## Architecture (summary)

Resources:

- Droplet (Ubuntu 24.04) with cloud-init user_data
- DNS A + wildcard records
- DigitalOcean firewall (ingress: 22,80,443)
- Uploaded SSH public key
- Caddy static site + vocab app via Docker Compose + systemd unit
- Outputs: droplet_name, droplet_ip

Cloud-init (idempotent) configures: user `akash`, Docker + compose plugin, log rotation (json-file), fail2ban, unattended upgrades, UFW (22/80/443), Caddy assets under /opt/caddy, vocab app site snippet, systemd unit caddy-compose.service (Type=simple, Restart=on-failure).

## Variables

| Name                | Description                                | Default                                       | Sensitive |
| ------------------- | ------------------------------------------ | --------------------------------------------- | --------- |
| digitalocean_token  | DO API token (pass via env)                | n/a                                           | yes       |
| domain              | Apex domain (provisions root + wildcard A) | n/a                                           | no        |
| name_prefix         | Base name for droplet (UUID suffix added)  | "do-vps"                                      | no        |
| region              | DO region slug                             | "lon1"                                        | no        |
| size                | Droplet size                               | "s-1vcpu-512mb-10gb"                          | no        |
| image               | Base image                                 | "ubuntu-24-04-x64"                            | no        |
| ssh_public_key_path | Path to local public key                   | "~/.ssh/id_rsa.pub"                           | no        |
| dns_ttl             | TTL for A records                          | 1800                                          | no        |
| caddy_image         | Prebuilt Caddy image with DO DNS module    | "ghcr.io/aceakash/caddy-digitalocean:2.10.0"  | no        |
| username            | Login username provisioned by cloud-init   | "akash"                                       | no        |

Local: droplet name = "${var.name_prefix}-${substr(uuid(),0,6)}" (new name each apply => replacements).

## Quickstart

```bash
# 0. Export token (or use TF_VAR_digitalocean_token)
export DIGITALOCEAN_TOKEN="<token>"

# 1. Format + init + validate
terraform fmt -recursive
terraform init
terraform validate

# 2. Plan (substitute with your values)
terraform plan \
  -var="digitalocean_token=$DIGITALOCEAN_TOKEN" \
  -var="domain=untilfalse.com" \
  -var="ssh_public_key_path=$HOME/.ssh/iuntilfalse_id_rsa.pub"

# 3. Apply (substitute with your values)
terraform apply \
  -var="digitalocean_token=$DIGITALOCEAN_TOKEN" \
  -var="domain=untilfalse.com" \
  -var="ssh_public_key_path=$HOME/.ssh/iuntilfalse_id_rsa.pub"
```

Check outputs:

```bash
terraform output
terraform output -raw droplet_ip
```

## Destroy

```bash
terraform destroy -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
```

## Caddy static site

On boot, systemd runs caddy-compose.service (Type=simple, Restart=on-failure) to start the Caddy container serving untilfalse.com and www.untilfalse.com, plus the vocab app at vocab.untilfalse.com. TLS via DNS-01 with DigitalOcean.

Status:

```bash
docker ps | grep caddy
docker logs caddy | head -n 50
```

## Token rotation

```bash
sudo sed -i "s/^DIGITALOCEAN_TOKEN=.*/DIGITALOCEAN_TOKEN=<new_token>/" /opt/caddy/.env
docker compose -f /opt/caddy/docker-compose.yml restart caddy
# Optional force renew
docker exec caddy caddy renew --force
```
