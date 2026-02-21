resource "hcloud_firewall" "vps_fw" {
  name = "${var.name_prefix}-fw"

  rule {
    description = "Allow SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow HTTP"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Coolify websocket"
    direction   = "in"
    protocol    = "tcp"
    port        = "6001"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Coolify terminal"
    direction   = "in"
    protocol    = "tcp"
    port        = "6002"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description     = "Allow all outbound TCP"
    direction       = "out"
    protocol        = "tcp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description     = "Allow all outbound UDP"
    direction       = "out"
    protocol        = "udp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description     = "Allow all outbound ICMP"
    direction       = "out"
    protocol        = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
}
