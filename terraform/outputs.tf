output "droplet_ip" {
  description = "Droplet IPv4 address"
  value       = digitalocean_droplet.vps.ipv4_address
}

output "droplet_name" {
  description = "Droplet name"
  value       = digitalocean_droplet.vps.name
}
