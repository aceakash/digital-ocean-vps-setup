# Copilot Instructions for AI Coding Agents

**Update this file whenever major project conventions, workflows, or architectural decisions are made.**

## AI Coding Agent Instructions (DigitalOcean Terraform VPS)

Update this file when conventions or architecture change. Keep guidance concrete and project-specific.

### Architecture Overview

Single Terraform root module provisions: Droplet (Ubuntu 24.04), DNS A + wildcard records, DO firewall, SSH key. Cloud-init bootstraps Docker, log rotation (json-file), fail2ban, UFW (22/80/443), unattended upgrades, non-root user `akash` with sudo + docker groups.

### Key Files & Roles

- `versions.tf`: Pins Terraform >=1.5.0 and DO provider ~>2.24.
- `providers.tf`: Uses `var.digitalocean_token` (never hardcode token).
- `variables.tf`: Tunables (region, size, image, domain, ssh key path, name_prefix). Token marked `sensitive`.
- `variables.tf` also defines `dns_ttl` (default 1800) allowing DNS cache tuning.
- `locals.tf`: `local.name = "${var.name_prefix}-${substr(uuid(), 0, 6)}"` unique droplet name per apply.
- `droplet.tf`: Main droplet; injects `cloud-init.yaml` via `templatefile()` with SSH key + username.
- `cloud-init.yaml`: Idempotent setup commands (avoid adding non-idempotent stateful ops).
- `firewall.tf`: Explicit ingress (22/80/443) + broad egress.
- `dns-records.tf`: Root (@) and wildcard (\*) A records to droplet IPv4.
- `ssh.tf`: Uploads local public key to DO; fingerprint referenced by droplet.
- `outputs.tf`: `droplet_ip`, `droplet_name`.
- `terraform/README.md`: Quickstart workflow.

### Standard Workflow

```bash
export DIGITALOCEAN_TOKEN=...                 # DO API token
terraform fmt -recursive
terraform init
terraform validate
terraform plan   -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=example.com"
terraform apply  -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=example.com"
```

Option: set `TF_VAR_digitalocean_token` / `TF_VAR_domain` to skip `-var` flags.

### Conventions & Patterns

- Secrets: Always pass token as var/environment, not committed.
- Naming: Use `var.name_prefix` consistently; only the droplet appends UUID for uniqueness.
- Ports: If opening a new inbound port, update BOTH `firewall.tf` (new inbound_rule) and `cloud-init.yaml` UFW commands.
- User data changes trigger droplet replacement; review plan before apply.
- Keep cloud-init commands small & idempotent (use heredocs for multi-line config like existing `daemon.json`).
- DNS assumes single droplet host; expanding to multiple requires refactor (module per droplet or service-specific records).

### Safe Extension Examples

- Add monitoring: Append an idempotent command in `cloud-init.yaml` `runcmd:`.
- New port (8080): Add firewall inbound rule + `ufw allow 8080` line before enable.
- Remote state: Add backend block in new `state.tf`; document here.
- Multiple droplets: Introduce `modules/droplet` and iterate count or separate module calls.

### Change Review Checklist

1. New variable? Added to `variables.tf`, documented here, referenced in resources.
2. Port change? Firewall + UFW aligned.
3. Cloud-init edit? Syntax OK, idempotent, triggers replace only if needed.
4. Provider/version bump? Adjust `versions.tf`; run `terraform init -upgrade`.
5. Naming impact? DNS expectations preserved.

### Destruction

```bash
terraform destroy -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=example.com"
```

Changing UUID logic or `name_prefix` creates new droplet instead of in-place update.

### Avoid

- Hardcoding IPs in DNS resources.
- Removing `sensitive = true` from token variable.
- Embedding large scripts inline in `.tf` (keep in `cloud-init.yaml`).

### Agent Guidance

For PRs: run `fmt`, `validate`, then capture `plan` diff summary (add/replace/destroy counts). Keep edits minimal and aligned with patterns above; update this file if conventions shift.

<!-- End of agent instructions -->
