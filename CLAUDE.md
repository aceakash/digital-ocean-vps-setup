# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Read and follow `docs/instructions.md`** — it contains guardrails, workflow rules, and process conventions that apply to every interaction.

## Project Purpose

Repeatable Terraform setup for a single DigitalOcean droplet hosting personal containerized web apps behind Caddy with wildcard TLS (DNS-01 via DigitalOcean). Application containers live in separate repos and connect to a shared Docker network (`proxy`).

## Architecture

Single Terraform root module (`terraform/`) provisions: Ubuntu 24.04 droplet, DNS A + wildcard records, DO firewall (22/80/443), SSH key. Cloud-init (`cloud-init.yaml`) bootstraps the droplet with user `akash`, Docker + compose plugin, fail2ban, UFW, unattended upgrades, Docker log rotation (json-file), and a Caddy static site managed via systemd unit (`caddy-compose.service`, Type=simple, Restart=on-failure).

A custom Caddy image with the DigitalOcean DNS plugin is built from `caddy-digitalocean-docker/Dockerfile` and published to GHCR as a multi-arch image.

External apps are deployed independently to `/opt/apps/<app>/` with their own compose files joining the shared `proxy` network, plus a Caddy site snippet in `/opt/caddy/sites/`. No Terraform changes needed thanks to wildcard DNS. See `cicd.md` for the full deployment guide.

## Common Commands

A top-level `Makefile` wraps Terraform commands so they can be run from the repo root:

```bash
make validate   # fmt-check + init + validate (default target, mirrors CI)
make fmt        # auto-fix formatting
make plan       # terraform plan (runs init first)
make apply      # terraform apply (runs init first)
make destroy    # terraform destroy (runs init first)
```

Or run Terraform directly from the `terraform/` directory:

```bash
cd terraform
terraform fmt -check -recursive
terraform init -input=false -backend=false
terraform validate
```

Variables are supplied via `terraform.tfvars` or environment variables (`TF_VAR_digitalocean_token`, `TF_VAR_domain`).

## CI

GitHub Actions workflow (`.github/workflows/terraform-validate.yml`) runs `fmt -check`, `init`, and `validate` on pushes/PRs touching `terraform/**`. Terraform state is local (gitignored).

## Key Conventions

- **Port changes**: update BOTH `firewall.tf` (inbound_rule) AND `cloud-init.yaml` (UFW commands) in sync.
- **Cloud-init edits trigger droplet replacement** — always review the plan before apply.
- **Cloud-init commands must be idempotent**. Use heredocs for multi-line configs.
- **Secrets**: DO token is marked `sensitive` in `variables.tf`. Currently embedded in user_data for convenience; target state is manual `/opt/caddy/.env` placement post-provision.
- **Naming**: `var.name_prefix` is used consistently for all resource names.
- **New variables**: add to `variables.tf`, reference in resources, document in copilot instructions.
- **Version pins**: Terraform >= 1.5.0, DO provider ~> 2.24 (see `versions.tf`). Bumps require `terraform init -upgrade`.
- Always confirm with the user before making changes. Make small, incremental changes.
- For PRs: run `fmt`, `validate`, then capture `plan` diff summary.

## Key Files

- `Makefile` — top-level Make targets wrapping Terraform commands (validate, fmt, plan, apply, destroy).
- `terraform/cloud-init.yaml` — droplet bootstrap (user, Docker, Caddy assets under `/opt/caddy/`, systemd unit, hardening). This is the most complex file; changes here replace the droplet.
- `terraform/droplet.tf` — droplet resource; injects cloud-init via `templatefile()`.
- `terraform/firewall.tf` — ingress rules (must stay aligned with UFW in cloud-init).
- `terraform/dns-records.tf` — root + wildcard A records.
- `caddy-digitalocean-docker/Dockerfile` — multi-stage build: xcaddy compiles Caddy v2.10.0 with DO DNS plugin.
- `cicd.md` — complete guide for deploying app containers to the droplet.
- `docs/instructions.md` — coding agent guardrails, workflow rules, and process conventions. Follow these on every interaction.
