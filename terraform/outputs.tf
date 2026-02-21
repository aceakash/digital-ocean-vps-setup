output "server_ip" {
  description = "Server IPv4 address"
  value       = hcloud_server.vps.ipv4_address
}

output "server_name" {
  description = "Server name"
  value       = hcloud_server.vps.name
}

output "coolify_url" {
  description = "Coolify dashboard URL"
  value       = "http://${hcloud_server.vps.ipv4_address}:8000"
}
