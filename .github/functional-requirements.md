<!-- Functional Requirements for DigitalOcean VPS Setup -->

# Scope

Repeatable DigitalOcean VPS setup for personal containerized web apps behind Caddy.

# Core Decisions (Locked)

1. Docker + Docker Compose (v2).
2. Reverse proxy: Caddy — wildcard (*.untilfalse.com) certificate via DNS-01.
3. TLS: DNS-01 only; Caddy uses DIGITALOCEAN_TOKEN to create TXT records and auto-renew.
4. OS: Ubuntu 24.04 LTS.
5. Provisioning: Terraform droplet + cloud-init bootstrap script.
6. IPv6: Disabled.
7. Backups: No DO backups; no snapshot schedule.
8. Monitoring: DigitalOcean basic graphs only.
9. Initial Apps: 2 stateless web/API + 1 Caddy.
10. Storage: Default root disk only.
11. SSH:
    - User: akash
    - Root login: disabled
    - Auth: SSH key only
    - fail2ban: enabled
    - unattended-upgrades: enabled
12. Firewall: Inbound only 22, 80, 443.
13. Logs: Docker json-file rotation (10m / 150 files).
14. Deployment Workflow: GHCR + GitHub Actions build/push; Watchtower auto-update (300s, no stopped containers, prune yes; webhook deferred).
15. Secrets Management: Hybrid (.env.example tracked + runtime .env ignored + GitHub Actions secrets for build-time injection).

# Terraform Layout (Option A - Flat)

Directory: terraform/

Files:

Repeatable DigitalOcean VPS setup for personal containerized web apps behind Caddy. This repository now provisions only the infrastructure and a static Caddy landing page; application containers live in separate repositories and join a shared external Docker network (`proxy`).
- providers.tf (DigitalOcean provider config)
- variables.tf (token, region, size, domain, ssh key path)
- locals.tf (name prefix, tags)
- ssh.tf (SSH key resource)
9. Initial Apps (in this repo): Caddy static site only. Application services are external and will be deployed separately.
- droplet.tf (droplet + user_data template)
- firewall.tf (ports 22,80,443 only)
13. Logs: Docker json-file rotation (10m / 150 files) configured in daemon.json.
- dns-records.tf (root domain + wildcard A record)
15. Secrets Management: Hybrid (.env.example tracked + runtime .env ignored + GitHub Actions secrets for build-time injection). DO token currently passed via cloud-init for convenience; target state is post-provision manual placement of `/opt/caddy/.env`.
- cloud-init.yaml (user creation, hardening, Docker install, log rotation)

State: local (terraform.tfstate gitignored). Modular expansion deferred.
Region: Default variable `lon1` (configurable via `var.region`).
# Infrastructure Baseline
Containers: 1 initial (Caddy). Future app containers deployed independently.
- Region: AMS3
- Droplet: Basic 1 vCPU / 512MB RAM
- Bandwidth: Light (<250GB/mo)
1. Security headers (HSTS, CSP, etc.) — IMPLEMENTED in Caddyfile.
2. Secret hygiene: remove token from user_data and adopt manual or managed secret provisioning.
3. Observability expansion (metrics/log aggregation).
4. Future stateful backup/restore policy.
5. Watchtower webhook + event scope.
6. CI workflow(s) for image build/publish & deployment.
7. Secret classification (build-time vs runtime values list).
8. Remote Terraform state backend.
2. Observability expansion (metrics/log aggregation)
3. Future stateful backup/restore policy
4. Watchtower webhook + event scope
Assumptions

Wildcard DNS record points to droplet IP; DIGITALOCEAN_TOKEN has DNS write scope only; apps are stateless and will expose internal container names on the `proxy` network for Caddy reverse_proxy directives.
6. Secret classification (build-time vs runtime values list)

# Constraints
Risks

Low RAM; no resilience/backups; minimal monitoring; secrets still embedded in user_data (temporary); external app deployment consistency not yet codified; no remote state locking.
Minimal moving parts; reproducible; upgradable path.

# Assumptions
Next Step

Migrate DO token handling out of cloud-init and document manual secret placement procedure.
Wildcard DNS record points to droplet IP; DIGITALOCEAN_TOKEN injected securely; apps stateless.

# Risks

Low RAM; no resilience/backups; minimal monitoring; security headers pending; no update notifications yet; secrets list not enumerated.

# Next Step

Define initial security headers policy.
