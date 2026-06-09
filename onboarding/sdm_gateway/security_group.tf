#################
# Security Group
#################
locals {
  security_group_details = {
    gateway = {
      type        = "gateway"
      name        = "${var.sdm_node_name}-gateways"
      description = "Open listening port for strongDM access"
    },
    relay = {
      type        = "relay"
      name        = "${var.sdm_node_name}-relays"
      description = "Egress only security group for strongDM relay"
    }
  }
  security_groups = compact([local.create_gateway ? "gateway" : "", local.create_relay ? "relay" : ""])
}

resource "aws_security_group" "this" {
  for_each = toset(local.security_groups)

  name        = local.security_group_details[each.key]["name"]
  description = local.security_group_details[each.key]["description"]

  vpc_id = var.deploy_vpc_id

  timeouts {
    delete = "2m"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge({ "Name" = "${var.sdm_node_name}-node" }, var.tags, )
}

# Gateway listen port: one ingress rule per allowed CIDR, only when gateway SG exists.
resource "aws_vpc_security_group_ingress_rule" "gateway_listen" {
  for_each = local.create_gateway ? toset(var.gateway_ingress_ips) : toset([])

  security_group_id = aws_security_group.this["gateway"].id
  description       = "strongDM gateway listen port"
  from_port         = var.gateway_listen_port
  to_port           = var.gateway_listen_port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Optional SSH ingress: applies to every SG (gateway and/or relay) when ssh_key is set.
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = var.ssh_key != null ? toset(local.security_groups) : toset([])

  security_group_id = aws_security_group.this[each.value].id
  description       = "SSH from operator source"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.ssh_source
}

# Allow all egress from every SG.
resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = toset(local.security_groups)

  security_group_id = aws_security_group.this[each.value].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
