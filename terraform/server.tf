resource "hcloud_server" "vps" {
  name        = local.name
  server_type = var.server_type
  image       = var.image
  location    = var.location

  ssh_keys     = [data.hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.vps_fw.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    ssh_authorized_key = data.hcloud_ssh_key.default.public_key
    username           = var.username
  })
}
