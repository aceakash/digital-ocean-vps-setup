# Terraform layout

This folder contains a minimal, repeatable Terraform layout to provision a DigitalOcean droplet and baseline resources according to the project's functional requirements.

Quickstart

0. Create a digital ocean token (API key) with the following scopes:

- droplet:all
- domain:all
- ssh_key:all
- tag:all
- firewall:all

1. Export your DigitalOcean token and ensure you have a public SSH key at `~/.ssh/id_rsa.pub` (or override via `ssh_public_key_path`).

   ```bash
   export DIGITALOCEAN_TOKEN="<token>"
   terraform init
   terraform plan -var="ssh_public_key_path=$HOME/.ssh/iuntilfalse_id_rsa.pub" -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
   terraform apply -var="ssh_public_key_path=$HOME/.ssh/iuntilfalse_id_rsa.pub" -var="digitalocean_token=$DIGITALOCEAN_TOKEN" -var="domain=untilfalse.com"
   ```

Notes

- `cloud-init.yaml` is a template that sets up user `akash`, installs Docker, enables `fail2ban`, `unattended-upgrades`, and configures basic UFW rules. It also writes a Docker `daemon.json` to configure json-file log rotation.
- Terraform state is expected to be local by default; add remote state when appropriate.
