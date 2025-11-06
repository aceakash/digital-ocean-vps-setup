locals {
  name = "${var.name_prefix}-${substr(uuid(), 0, 6)}"
}
