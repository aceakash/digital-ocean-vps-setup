variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner Cloud location"
  type        = string
  default     = "fsn1"
}

variable "server_type" {
  description = "Hetzner Cloud server type slug"
  type        = string
  default     = "cx22"
}

variable "image" {
  description = "Server image"
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_key_name" {
  description = "Name of an existing SSH key in your Hetzner Cloud account"
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
  default     = "vps"
}

variable "username" {
  description = "Login username provisioned by cloud-init"
  type        = string
  default     = "akash"
}
