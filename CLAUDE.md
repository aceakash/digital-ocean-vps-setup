# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Read and follow `docs/instructions.md`** — it contains guardrails, workflow rules, and process conventions that apply to every interaction.

## Project Purpose

Repeatable Terraform setup for a single Hetzner Cloud server running Coolify — a self-hosted PaaS that handles Docker, reverse proxy, SSL, and app deployments via a web UI. Wildcard DNS enables deploying new apps without Terraform changes.

## Architecture

Single Terraform root module (`terraform/`) provisions: Ubuntu 24.04 Hetzner server, DNS zone with A + wildcard records, Hetzner firewall (22/80/443/8000/6001/6002), SSH key. Cloud-init (`cloud-init.yaml`) bootstraps the server with user `akash`, fail2ban, unattended upgrades, and the Coolify install script. Coolify handles Docker installation, reverse proxy, SSL certificates, and app deployments.

## Common Commands

A top-level `Makefile` wraps Terraform commands so they can be run from the repo root:

```bash
make validate   # fmt-check + init + validate (default target, mirrors CI)
make fmt        # auto-fix formatting
make plan       # terraform plan (runs init first)
make apply      # terraform apply (runs init first)
make destroy    # terraform destroy (runs init first)
make clean      # remove .terraform/, lock file, and state files
```

Or run Terraform directly from the `terraform/` directory:

```bash
cd terraform
terraform fmt -check -recursive
terraform init -input=false -backend=false
terraform validate
```

Variables are supplied via `terraform.tfvars` or environment variables (`TF_VAR_hcloud_token`, `TF_VAR_domain`).

## CI

GitHub Actions workflow (`.github/workflows/terraform-validate.yml`) runs `fmt -check`, `init`, and `validate` on pushes/PRs touching `terraform/**`. Terraform state is local (gitignored).

## Key Conventions

- **Cloud-init edits trigger server replacement** — always review the plan before apply.
- **Cloud-init commands must be idempotent**.
- **Secrets**: Hetzner token is marked `sensitive` in `variables.tf`.
- **Naming**: `var.name_prefix` is used consistently for all resource names.
- **New variables**: add to `variables.tf`, reference in resources, document in copilot instructions.
- **Version pins**: Terraform >= 1.5.0, hcloud provider ~> 1.60 (see `versions.tf`). Bumps require `terraform init -upgrade`.
- Always confirm with the user before making changes. Make small, incremental changes.
- For PRs: run `fmt`, `validate`, then capture `plan` diff summary.

## Key Files

- `Makefile` — top-level Make targets wrapping Terraform commands (validate, fmt, plan, apply, destroy, clean).
- `terraform/cloud-init.yaml` — server bootstrap (user, Coolify install, hardening). Changes here replace the server.
- `terraform/server.tf` — server resource; injects cloud-init via `templatefile()`.
- `terraform/firewall.tf` — ingress/egress rules.
- `terraform/dns-records.tf` — DNS zone, root + wildcard A records.
- `docs/instructions.md` — coding agent guardrails, workflow rules, and process conventions. Follow these on every interaction.
