resource "digitalocean_record" "root_a" {
  domain = var.domain
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.vps.ipv4_address
  ttl    = 1800
}

resource "digitalocean_record" "wildcard_a" {
  domain = var.domain
  type   = "A"
  name   = "*"
  value  = digitalocean_droplet.vps.ipv4_address
  ttl    = 1800
}
