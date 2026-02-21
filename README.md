# VPS Setup — Hetzner + Coolify

Terraform configuration that provisions a Hetzner Cloud server running [Coolify](https://coolify.io) — a self-hosted PaaS for deploying containerized apps with automatic SSL.

## What gets provisioned

- **Server** — Hetzner CX22 (2 vCPU, 4 GB RAM), Ubuntu 24.04, hardened via cloud-init (non-root user, fail2ban, unattended upgrades)
- **DNS** — Hetzner DNS zone with A record for the apex domain + wildcard record (e.g. `*.example.com`)
- **Firewall** — inbound 22, 80, 443, 8000, 6001, 6002
- **Coolify** — installed via cloud-init, handles Docker, reverse proxy, SSL, and app deployments

## Required inputs

You must provide these variables (everything else has sensible defaults — see `terraform/variables.tf`):

- `hcloud_token` — Hetzner Cloud API token (sensitive)
- `domain` — apex domain to create records for (e.g. `example.com`)
- `ssh_key_name` — name of an existing SSH key in your Hetzner Cloud account

## Quickstart

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your token, domain, and SSH key name
cd ..

make plan
make apply
```

**Important:** Changing `cloud-init.yaml` or any input that affects user_data will replace the server, destroying all runtime state.

### After apply

The Coolify install script takes 5-10 minutes to complete after the server is created. Wait for cloud-init to finish:

```bash
IP=$(cd terraform && terraform output -raw server_ip)
ssh akash@$IP cloud-init status --wait
```

Then access the Coolify dashboard:

```
http://<server-ip>:8000
```

Set your admin password and start deploying apps through the Coolify UI.

**Nameservers:** Update your domain registrar to point to Hetzner's nameservers. DNS propagation can take up to 48 hours.

If something goes wrong, check cloud-init logs:

```bash
ssh akash@$IP sudo cat /var/log/cloud-init-output.log
```

## Validating changes

```bash
make validate
```

Or manually:

```bash
cd terraform
terraform fmt -check -recursive
terraform init -input=false -backend=false
terraform validate
```

This is what CI runs on every push/PR touching `terraform/`.

## Destroy

```bash
make destroy
```
