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

  dynamic "ingress" {
    for_each = local.security_group_details[each.key]["type"] == "gateway" ? [1] : []
    content {
      from_port   = var.gateway_listen_port
      to_port     = var.gateway_listen_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.ssh_key != null ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_source]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  timeouts {
    delete = "2m"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge({ "Name" = "${var.sdm_node_name}-node" }, var.tags, )
}
