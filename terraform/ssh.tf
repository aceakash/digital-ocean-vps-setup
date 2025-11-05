resource "digitalocean_ssh_key" "default" {
  name       = "${var.name_prefix}-key"
  public_key = file(var.ssh_public_key_path)
}
