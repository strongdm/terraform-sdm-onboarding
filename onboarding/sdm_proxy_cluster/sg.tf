resource "aws_security_group" "this" {
  name_prefix = "sdm-proxy-"

  vpc_id = var.vpc_id

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this_from_nlb" {
  security_group_id            = aws_security_group.this.id
  description                  = "Allow TCP:${local.container_proxy_port} from NLB"
  from_port                    = local.container_proxy_port
  to_port                      = local.container_proxy_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.nlb.id
}

resource "aws_vpc_security_group_egress_rule" "this_all" {
  security_group_id = aws_security_group.this.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "nlb" {
  name_prefix = "sdm-proxy-"

  vpc_id = var.vpc_id

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "nlb_traffic" {
  for_each = toset(var.ingress_cidr_blocks)

  security_group_id = aws_security_group.nlb.id
  description       = "Allow TCP:${var.traffic_port} ingress"
  from_port         = var.traffic_port
  to_port           = var.traffic_port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "nlb_all" {
  security_group_id = aws_security_group.nlb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
