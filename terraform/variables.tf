variable "digitalocean_token" {
  description = "DigitalOcean API token with DNS write / droplet create permissions"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "lon1"
}

variable "size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-1vcpu-512mb-10gb"
}

variable "image" {
  description = "Droplet image"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "ssh_key_name" {
  description = "Name of an existing SSH key in your DigitalOcean account"
  type        = string
}

variable "domain" {
  description = "Root domain to create records for (example: example.com)"
  type        = string
}

variable "dns_ttl" {
  description = "TTL (seconds) for created DNS A records"
  type        = number
  default     = 1800
}

variable "name_prefix" {
  description = "Name prefix for created resources"
  type        = string
  default     = "do-vps"
}

variable "caddy_image" {
  description = "Prebuilt Caddy image with DO DNS module"
  type        = string
  default     = "ghcr.io/aceakash/caddy-digitalocean:2.10.0"
}

variable "username" {
  description = "Login username provisioned by cloud-init"
  type        = string
  default     = "akash"
}
