resource "digitalocean_record" "root_a" {
  domain = var.domain
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.vps.ipv4_address
  ttl    = var.dns_ttl
}

resource "digitalocean_record" "wildcard_a" {
  domain = var.domain
  type   = "A"
  name   = "*"
  value  = digitalocean_droplet.vps.ipv4_address
  ttl    = var.dns_ttl
}
