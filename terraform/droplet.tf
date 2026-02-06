resource "digitalocean_droplet" "vps" {
  name   = local.name
  region = var.region
  size   = var.size
  image  = var.image

  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  ipv6 = false

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    ssh_authorized_key = file(var.ssh_public_key_path)
    username           = var.username
    digitalocean_token = var.digitalocean_token
    caddy_image        = var.caddy_image
    domain             = var.domain
  })

  tags = [var.name_prefix]
}
