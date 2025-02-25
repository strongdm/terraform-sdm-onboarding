resource "aws_security_group" "this" {
  name_prefix = "sdm-proxy-"

  vpc_id = var.vpc_id

  ingress {
    description     = "Allow TCP:${local.container_proxy_port} from NLB"
    from_port       = local.container_proxy_port
    to_port         = local.container_proxy_port
    security_groups = [aws_security_group.nlb.id]
    protocol        = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "nlb" {
  name_prefix = "sdm-proxy-"

  vpc_id = var.vpc_id

  ingress {
    description = "Allow TCP:${var.traffic_port} ingress"
    from_port   = var.traffic_port
    to_port     = var.traffic_port
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
