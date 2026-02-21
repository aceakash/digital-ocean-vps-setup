resource "hcloud_zone" "main" {
  name = var.domain
  mode = "primary"
  ttl  = var.dns_ttl
}

resource "hcloud_zone_rrset" "root_a" {
  zone = hcloud_zone.main.name
  name = "@"
  type = "A"
  ttl  = var.dns_ttl

  records = [
    { value = hcloud_server.vps.ipv4_address },
  ]
}

resource "hcloud_zone_rrset" "wildcard_a" {
  zone = hcloud_zone.main.name
  name = "*"
  type = "A"
  ttl  = var.dns_ttl

  records = [
    { value = hcloud_server.vps.ipv4_address },
  ]
}
