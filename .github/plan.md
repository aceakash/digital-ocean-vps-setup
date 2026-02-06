# Current plan and next steps

This file captures the current repository state, what is implemented, and the prioritized path forward.

## Current snapshot (implemented)

- Terraform root module provisions a single DigitalOcean droplet + DNS A records (root + wildcard) + firewall + SSH key.
  - `terraform/*` files: versions, providers, variables, locals, ssh, droplet, firewall, dns-records, outputs.
  - `terraform/cloud-init.yaml`: creates user `akash`; installs Docker & compose plugin, fail2ban, unattended-upgrades; sets Docker json-file log rotation; enables UFW (22/80/443); writes Caddy assets (`/opt/caddy/Caddyfile`, `/opt/caddy/docker-compose.yml`, static `index.html`, `/opt/caddy/sites/vocab.caddy`); installs systemd `caddy-compose.service` (Type=simple, Restart=on-failure) and helper script `/usr/local/bin/caddy-compose-up.sh`.
  - Caddy serves `untilfalse.com` and `www.untilfalse.com` with security headers (HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy) and wildcard DNS-01 issuance via DigitalOcean token.
  - Vocab app (`ghcr.io/aceakash/vocab:0.1.0`) deployed as a compose service with Caddy site snippet at `vocab.untilfalse.com`.
- `caddy-digitalocean-docker/Dockerfile`: multi-stage build of Caddy v2.10.0 with DO DNS plugin, published as multi-arch image to GHCR.
- `.github/workflows/terraform-validate.yml` validates fmt + config.
- `.gitignore` excludes local Terraform state & artifacts.

## High-level assumptions

- Droplet size `s-1vcpu-512mb-10gb` acceptable for static site + vocab app at low traffic.
- Future apps will live in separate repositories and connect to the external Docker network `proxy` created on the host.
- Watchtower & additional app reverse proxy snippets are future additions.
- DigitalOcean token currently embedded in user_data (to be improved for secret hygiene).

## How to validate / resume locally

```bash
export DIGITALOCEAN_TOKEN="<your_do_token>"
cd terraform
terraform init
terraform validate
terraform plan -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
terraform apply -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
```

After apply (on droplet): Caddy auto-starts via systemd; check `docker ps`, `docker logs caddy` and visit https://www.untilfalse.com.

## Recommended next steps (priority)

1. Secret hygiene: remove DO token from cloud-init and switch to manual `/opt/caddy/.env` placement (or managed secret tool); adjust systemd start logic accordingly.
2. Remote state backend (`backend.tf`) for collaboration (Terraform Cloud, S3 + DynamoDB lock, or DO Spaces + external lock strategy).
3. App integration contract (`APP_INTEGRATION.md`) describing snippet drop + `caddy reload` and container naming conventions.
4. CI workflows for external app repos (build/push to GHCR, deploy via SSH or runner on droplet).
5. Watchtower service (interval 300s, `--cleanup`, `--revive-stopped=false`) + future webhook for scoped updates.
6. Secrets classification doc (`SECRETS.md`) listing build-time vs runtime secrets and rotation procedures.
7. Observability baseline (lightweight metrics/log collection; evaluate fail2ban log forwarding).
8. Harden baseline (explicit unattended-upgrades config, tighter fail2ban jail, potential egress restrictions, Docker resource limits for future apps).

## Quick wins

1. Implement token removal (small cloud-init & droplet change + doc update).
2. Add `backend.tf` for remote state.
3. Draft `SECRETS.md` and `APP_INTEGRATION.md` scaffolds.

## Status checklist

- Security headers: done.
- Static site: done.
- Systemd orchestration: done (Type=simple, Restart=on-failure).
- Vocab app: done (compose service + Caddy snippet).
- Remote state: pending.
- Token hygiene: pending.
- App integration docs: pending.
- Watchtower: pending.
- Secrets classification: pending.
- Extended CI (images/deploy): pending.

## Immediate pick-up suggestion

Start with token hygiene (remove embedding) then add remote state; both are low-risk, foundational improvements.

## Notes for future

- Removing token from user_data triggers droplet replacement; plan rotate/replace window.
- Introduce tests/validation for Caddy config with `docker run caddy caddy validate --config /opt/caddy/Caddyfile` in CI later.
- Consider multi-droplet architecture only after remote state + secret hygiene are solid.

---

Ask for any of the quick wins and I can implement immediately.
