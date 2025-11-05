variable "digitalocean_token" {
  description = "DigitalOcean API token with DNS write / droplet create permissions"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "ams3"
}

variable "size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-1vcpu-512mb"
}

variable "image" {
  description = "Droplet image"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key to upload to the droplet"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "domain" {
  description = "Root domain to create records for (example: untilfalse.com)"
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for created resources"
  type        = string
  default     = "do-vps"
}
