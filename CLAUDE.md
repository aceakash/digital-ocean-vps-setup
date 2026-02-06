# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Repeatable Terraform setup for a single DigitalOcean droplet hosting personal containerized web apps behind Caddy with wildcard TLS (DNS-01 via DigitalOcean). Application containers live in separate repos and connect to a shared Docker network (`proxy`).

## Architecture

Single Terraform root module (`terraform/`) provisions: Ubuntu 24.04 droplet, DNS A + wildcard records, DO firewall (22/80/443), SSH key. Cloud-init (`cloud-init.yaml`) bootstraps the droplet with user `akash`, Docker + compose plugin, fail2ban, UFW, unattended upgrades, Docker log rotation (json-file), and a Caddy static site + vocab app managed via systemd unit (`caddy-compose.service`, Type=simple, Restart=on-failure).

A custom Caddy image with the DigitalOcean DNS plugin is built from `caddy-digitalocean-docker/Dockerfile` and published to GHCR as a multi-arch image.

External apps are added by appending a service to `/opt/caddy/docker-compose.yml` and a Caddy site snippet, then reloading Caddy (no Terraform changes needed thanks to wildcard DNS).

## Common Commands

All Terraform commands run from the `terraform/` directory.

```bash
# Validate (what CI runs)
cd terraform
terraform fmt -check -recursive
terraform init -input=false -backend=false
terraform validate

# Format
terraform fmt -recursive

# Plan
export DIGITALOCEAN_TOKEN="<token>"
terraform init
terraform plan -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"

# Apply
terraform apply -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"

# Destroy
terraform destroy -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
```

Alternative: set `TF_VAR_digitalocean_token` and `TF_VAR_domain` environment variables to skip `-var` flags.

## CI

GitHub Actions workflow (`.github/workflows/terraform-validate.yml`) runs `fmt -check`, `init`, and `validate` on pushes/PRs touching `terraform/**`. Terraform state is local (gitignored).

## Key Conventions

- **Port changes**: update BOTH `firewall.tf` (inbound_rule) AND `cloud-init.yaml` (UFW commands) in sync.
- **Cloud-init edits trigger droplet replacement** — always review the plan before apply.
- **Cloud-init commands must be idempotent**. Use heredocs for multi-line configs.
- **Secrets**: DO token is marked `sensitive` in `variables.tf`. Currently embedded in user_data for convenience; target state is manual `/opt/caddy/.env` placement post-provision.
- **Naming**: `var.name_prefix` is used consistently; only the droplet appends a UUID suffix (new name each apply = replacement).
- **New variables**: add to `variables.tf`, reference in resources, document in copilot instructions.
- **Version pins**: Terraform >= 1.5.0, DO provider ~> 2.24 (see `versions.tf`). Bumps require `terraform init -upgrade`.
- Always confirm with the user before making changes. Make small, incremental changes.
- For PRs: run `fmt`, `validate`, then capture `plan` diff summary.

## Key Files

- `terraform/cloud-init.yaml` — droplet bootstrap (user, Docker, Caddy assets under `/opt/caddy/`, systemd unit, hardening). This is the most complex file; changes here replace the droplet.
- `terraform/droplet.tf` — droplet resource; injects cloud-init via `templatefile()`.
- `terraform/firewall.tf` — ingress rules (must stay aligned with UFW in cloud-init).
- `terraform/dns-records.tf` — root + wildcard A records.
- `caddy-digitalocean-docker/Dockerfile` — multi-stage build: xcaddy compiles Caddy v2.10.0 with DO DNS plugin.
- `.github/plan.md` — current project status and prioritized next steps.
- `.github/functional-requirements.md` — locked architectural decisions.
- `cicd.md` — CI/CD deployment pattern for external app containers.
