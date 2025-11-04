<!-- Functional Requirements for DigitalOcean VPS Setup -->

# Scope

Repeatable DigitalOcean VPS setup for personal containerized web apps behind Caddy.

# Core Decisions (Locked)

1. Docker + Docker Compose (v2).
2. Reverse Proxy: Caddy (wildcard \*.untilfalse.com via DNS-01).
3. TLS: DNS-01 only with DIGITALOCEAN_TOKEN; default renewal.
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
13. Logs: Docker json-file rotation (10m / 5 files).
14. Deployment Workflow: GHCR + GitHub Actions build/push; Watchtower auto-update (300s, no stopped containers, prune yes; webhook deferred).
15. Secrets Management: Hybrid (.env.example tracked + runtime .env ignored + GitHub Actions secrets for build-time injection).

# Terraform Layout (Option A - Flat)

Directory: terraform/

Files:

- versions.tf (Terraform / provider constraints)
- providers.tf (DigitalOcean provider config)
- variables.tf (token, region, size, domain, ssh key path)
- locals.tf (name prefix, tags)
- ssh.tf (SSH key resource)
- droplet.tf (droplet + user_data template)
- firewall.tf (ports 22,80,443 only)
- dns-records.tf (root domain + wildcard A record)
- outputs.tf (droplet IP)
- cloud-init.yaml (user creation, hardening, Docker install, log rotation)

State: local (terraform.tfstate gitignored). Modular expansion deferred.

# Infrastructure Baseline

- Region: AMS3
- Droplet: Basic 1 vCPU / 512MB RAM
- Bandwidth: Light (<250GB/mo)
- Containers: 3 initial (2 apps + Caddy)
- No databases/caches/volumes initially

# Open Items

1. Security headers (HSTS, CSP, etc.)
2. Observability expansion (metrics/log aggregation)
3. Future stateful backup/restore policy
4. Watchtower webhook + event scope
5. CI workflow file specifics (caching, tagging, secret injection)
6. Secret classification (build-time vs runtime values list)

# Constraints

Minimal moving parts; reproducible; upgradable path.

# Assumptions

Wildcard DNS record points to droplet IP; DIGITALOCEAN_TOKEN injected securely; apps stateless.

# Risks

Low RAM; no resilience/backups; minimal monitoring; security headers pending; no update notifications yet; secrets list not enumerated.

# Next Step

Define initial security headers policy.
