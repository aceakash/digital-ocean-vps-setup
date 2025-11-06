## In progress

### [soi-943] Static website not reachable (untilfalse.com)

#### Summary

Resolved. Caddy now running with custom multi-arch image (v2.10.0 + DigitalOcean DNS plugin). Site responds over HTTP/HTTPS.

#### Environment

Ubuntu 24.04 Droplet (Terraform + cloud-init). Systemd oneshot unit: `caddy-compose.service`.

#### Final Timeline

1. Network label warning blocked container.
2. Removed manual proxy network.
3. Missing dns.providers.digitalocean module caused exit.
4. In-droplet build failures (Go version + DNS timeouts).
5. Plugin required Caddy ≥2.10.0; updated target.
6. Local build succeeded (v2.10.0 + plugin).
7. Private GHCR image prevented pull.
8. Made image public; architecture mismatch (arm64 on amd64).
9. Built multi-arch image via buildx.
10. Pulled correct manifest on droplet; service started successfully.
11. Step 3 verification (HTTP/HTTPS) succeeded (2025-11-06 ~11:XX UTC).

#### Root Causes

- Initial: pre-created unlabeled Docker network.
- Primary: using stock Caddy without required DNS plugin.
- Secondary: version/toolchain mismatch (plugin needed newer Caddy + Go).
- Deployment: private & single-arch image on mismatched host.

#### Actions Taken

- Adjusted cloud-init (removed network creation).
- Built/published multi-arch custom Caddy image with DO DNS plugin.
- Made image public.
- Restarted systemd compose unit; verified site availability.

#### Current Status

Site reachable; wildcard cert issuance expected via DNS-01 (monitor logs for certificate events).

#### Recommended Follow-ups

- Remove DigitalOcean token from user_data (external secret provisioning).
- Change systemd unit to Type=simple with Restart=on-failure.
- Add health check monitoring.
- Tag image explicitly (e.g. 2.10.0-dns-do) and automate CI build.

### Completed

- [soi-943] Static website not reachable (untilfalse.com) — FIXED (2025-11-06)
