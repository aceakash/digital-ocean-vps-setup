<!-- Functional Requirements for DigitalOcean VPS Setup -->

# Scope

Repeatable DigitalOcean VPS setup for personal containerized web apps behind Caddy. This repository provisions infrastructure and a static Caddy landing page plus initial app containers; future application containers live in separate repositories and join a shared external Docker network (`proxy`).

# Core Decisions (Locked)

1. Docker + Docker Compose (v2).
2. Reverse proxy: Caddy — wildcard (*.untilfalse.com) certificate via DNS-01.
3. TLS: DNS-01 only; Caddy uses DIGITALOCEAN_TOKEN to create TXT records and auto-renew.
4. OS: Ubuntu 24.04 LTS.
5. Provisioning: Terraform droplet + cloud-init bootstrap script.
6. IPv6: Disabled.
7. Backups: No DO backups; no snapshot schedule.
8. Monitoring: DigitalOcean basic graphs only.
9. Initial Apps (in this repo): Caddy static site + vocab app. Future app containers deployed independently.
10. Storage: Default root disk only.
11. SSH:
    - User: akash
    - Root login: disabled
    - Auth: SSH key only
    - fail2ban: enabled
    - unattended-upgrades: enabled
12. Firewall: Inbound only 22, 80, 443.
13. Logs: Docker json-file rotation (10m / 150 files) configured in daemon.json.
14. Deployment Workflow: GHCR + GitHub Actions build/push; Watchtower auto-update (300s, no stopped containers, prune yes; webhook deferred).
15. Secrets Management: Hybrid (.env.example tracked + runtime .env ignored + GitHub Actions secrets for build-time injection). DO token currently passed via cloud-init for convenience; target state is post-provision manual placement of `/opt/caddy/.env`.

# Terraform Layout (Flat)

Directory: terraform/

Files:
- providers.tf (DigitalOcean provider config)
- variables.tf (token, region, size, domain, ssh key path, name_prefix, caddy_image, username)
- locals.tf (name prefix + UUID)
- ssh.tf (SSH key resource)
- droplet.tf (droplet + user_data template)
- firewall.tf (ports 22,80,443 only)
- dns-records.tf (root domain + wildcard A record)
- cloud-init.yaml (user creation, hardening, Docker install, log rotation, Caddy + vocab setup)
- outputs.tf (droplet_ip, droplet_name)
- versions.tf (Terraform >= 1.5.0, DO provider ~> 2.24)

State: local (terraform.tfstate gitignored). Modular expansion deferred.

# Infrastructure Baseline

- Region: lon1 (configurable via `var.region`)
- Droplet: s-1vcpu-512mb-10gb
- Bandwidth: Light (<250GB/mo)
- Containers: Caddy + vocab. Future app containers deployed independently.

# Implemented

1. Security headers (HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy) — in Caddyfile.
2. Systemd unit: Type=simple with Restart=on-failure.
3. Vocab app deployed via cloud-init (docker-compose service + Caddy site snippet).

# Pending

1. Secret hygiene: remove token from user_data and adopt manual or managed secret provisioning.
2. Observability expansion (metrics/log aggregation).
3. Future stateful backup/restore policy.
4. Watchtower webhook + event scope.
5. CI workflow(s) for image build/publish & deployment.
6. Secret classification (build-time vs runtime values list).
7. Remote Terraform state backend.

# Assumptions

Wildcard DNS record points to droplet IP; DIGITALOCEAN_TOKEN has DNS write scope only; apps are stateless and will expose internal container names on the `proxy` network for Caddy reverse_proxy directives.

# Risks

Low RAM; no resilience/backups; minimal monitoring; secrets still embedded in user_data (temporary); external app deployment consistency not yet codified; no remote state locking.

# Next Step

Migrate DO token handling out of cloud-init and document manual secret placement procedure.
