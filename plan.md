# Current plan and next steps

This file captures the current repository state, what was implemented from the functional requirements, verification steps you can run locally, and my recommended next steps so you can resume work later.

## Current snapshot (what I changed)

- Added a minimal Terraform layout under `terraform/` to provision a single DigitalOcean droplet and baseline resources.
  - `terraform/versions.tf` — provider and Terraform version requirements.
  - `terraform/providers.tf` — DigitalOcean provider (reads token from variable).
  - `terraform/variables.tf` — variables including `digitalocean_token`, `domain`, `ssh_public_key_path`, etc.
  - `terraform/locals.tf` — simple name local.
  - `terraform/ssh.tf` — `digitalocean_ssh_key` resource that uploads your public key.
  - `terraform/droplet.tf` — `digitalocean_droplet` using `cloud-init.yaml` template, IPv6 disabled.
  - `terraform/firewall.tf` — firewall allowing inbound 22, 80, 443 and unrestricted outbound.
  - `terraform/dns-records.tf` — adds both `@` and `*` A records pointing to droplet IPv4.
  - `terraform/outputs.tf` — outputs `droplet_ip` and `droplet_name`.
  - `terraform/cloud-init.yaml` — cloud-init template that creates user `akash`, installs Docker, Docker Compose plugin, fail2ban, unattended-upgrades, configures Docker json-file log rotation, and enables UFW rules for 22/80/443.
  - `terraform/README.md` — quickstart and notes for the Terraform module.
- Added `.gitignore` entries to exclude Terraform state and some local artifacts.
- Added GitHub Actions workflow: `.github/workflows/terraform-validate.yml` that runs `terraform fmt -check` and `terraform validate` for `terraform/**` changes.

## High-level assumptions made

- Droplet spec: `s-1vcpu-512mb` (per functional requirements). Change via variable `size` if needed.
- `akash` is the managed user; `root` is disabled in cloud-init.
- DNS wildcard (`*`) will point to the droplet IP (Terraform creates A records for `@` and `*`).
- Terraform state is local by default (no remote backend configured).
- No attempt was made to provision the application containers, Caddy config, or Watchtower — those are next items.

## How to validate / resume work locally

1. Ensure you have a DigitalOcean API token with appropriate permissions (DNS + droplet create). Save it to an env var when running Terraform:

```bash
export DIGITALOCEAN_TOKEN="<your_do_token>"
cd terraform
terraform init
terraform validate
terraform plan -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=example.com"
```

2. If `terraform plan` looks correct, apply:

```bash
terraform apply -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=example.com"
```

Notes:
- `cloud-init.yaml` will install Docker and set up basic hardening. The cloud-init uses the public key contents from `ssh_public_key_path` variable.
- The GitHub Actions CI added will validate formatting and HCL on pushes or PRs that touch `terraform/**`.

## Recommended next steps (priority-ordered)

1) Add a reusable Docker Compose + Caddy starter
   - Create `docker-compose.yml` (3 containers: caddy, app1, app2) and `caddy/Caddyfile` that implements the project's TLS and DNS-01 requirements (Caddy will need `DIGITALOCEAN_TOKEN` injected via environment or secret for DNS-01).
   - Purpose: gives a runnable example for the target platform and demonstrates security headers.
   - Risk: Caddy needs credentials for DNS-01; keep token in secrets only.

2) Implement recommended security headers in a Caddy configuration
   - Minimal set: HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Content-Security-Policy (tight default), and `Permissions-Policy` where applicable.
   - Purpose: closes open item in functional requirements (security headers).

3) Add CI workflow(s) for building and publishing images to GHCR and a deployment workflow
   - Build matrix: `docker build` per service, push to GHCR with tags (branch, commit SHA), use Actions cache for layers.
   - Separate deploy workflow that pulls images and updates the droplet (SSH + docker compose pull/up), or use a GitHub Action runner on the droplet (if you prefer).

4) Add Watchtower configuration and webhook handling (deferred in spec)
   - Add watchtower service in compose file with `--schedule` or interval (300s per requirements), set `--cleanup`, and configure to skip stopped containers.
   - Consider a small webhook receiver to control update scopes later.

5) Switch Terraform to remote state (recommended before using in production)
   - Use Terraform Cloud, S3 (with locking via DynamoDB), or DigitalOcean Spaces + locking strategy.
   - Purpose: enable team collaboration and avoid accidental resource duplication.

6) Enumerate and classify secrets (build-time vs runtime)
   - Create a `SECRETS.md` that lists which secrets are required at build and which at runtime.
   - Ensure `.env.example` remains tracked, and add runtime `.env` to `.gitignore` (already done).

7) Harden cloud-init and droplet baseline (optional)
   - Add explicit unattended-upgrades configuration, tighten fail2ban filters, rotate logs more conservatively for low-RAM droplets, and consider resource limits for Docker.

8) Add monitoring/observability baseline
   - Lightweight: expose container logs to local file and use DO metrics for CPU/memory.
   - Medium: forward logs to a log collector (deferred).

## Small recommended quick wins to implement now

- Add `terraform/backend.tf` for remote state (if you already have an S3/Bucket or Terraform Cloud account).
- Add `docker-compose.example.yml` and `caddy/Caddyfile.example` to demonstrate how to mount `DIGITALOCEAN_TOKEN` into Caddy for DNS-01.
- Add a short `SECRETS.md` describing where to put `DIGITALOCEAN_TOKEN` (GH Actions secrets vs droplet env) and the trust model.

## Safety & cost notes

- Applying the Terraform will create a real DigitalOcean droplet and DNS records; charges will apply according to your DO account.
- The droplet created by default is small (512MB). Production workloads may require larger sizes.

## Current todo list mapping

- Review functional requirements — completed
- Implement feature(s) — completed
- Add tests — completed (CI job added for terraform fmt/validate)
- Run lint/build/tests — not-started (run `terraform validate` locally or rely on CI)
- Document changes — in-progress (this `plan.md` is the first step)

## How I'd pick up from here (recommended immediate task to resume)

1. Create example `docker-compose.yml` + `caddy/Caddyfile` in a `compose/` or `infra/` folder and wire a GitHub Actions workflow that builds images and pushes to GHCR.
2. Add `terraform/backend.tf` for remote state.
3. Run `terraform validate` locally and push a branch to trigger the CI job.

## Contact notes / context for future you

- The functional requirements are in `.github/functional-requirements.md`. It lists locked decisions and open items (security headers, watchtower webhook, observability expansion).
- Cloud-init template is intentionally simple. If you later add more provisioning steps consider moving to a configuration management tool or a more advanced cloud-init setup.

----

If you want, I can implement one of the recommended next steps now — pick one (e.g., add a `docker-compose.yml` + `Caddyfile` example, or add remote Terraform state config) and I'll proceed and update the plan accordingly.
