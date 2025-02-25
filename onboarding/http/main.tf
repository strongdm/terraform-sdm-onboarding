terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 4.0.0"
    }
  }
}

# ---------------------------------------------------------------------------- #
# Create an EC2 instance
# ---------------------------------------------------------------------------- #
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
resource "aws_security_group" "web_page" {
  name_prefix = "${var.name}-web-page"
  description = "allow inbound from strongDM gateway"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.name}-http" }, var.tags)
}

resource "aws_security_group_rule" "allow_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.web_page.id
}
resource "aws_security_group_rule" "allow_http_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.web_page.id
}

resource "aws_instance" "web_page" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_page.id]

  # Configures a simple HTTP web page
  user_data = templatefile("${path.module}/templates/http_install/http_install.tftpl", { SSH_PUB_KEY = var.ssh_pubkey })
  tags      = merge({ Name = "${var.name}-http" }, var.tags)
}
# ---------------------------------------------------------------------------- #
# Add the web page to strongDM
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "web_page" {
  http_no_auth {
    name             = "${var.name}-http"
    url              = "http://${aws_instance.web_page.private_ip}"
    default_path     = "/"
    healthcheck_path = "/"
    subdomain        = "simple-web-page"

    proxy_cluster_id = var.proxy_cluster_id

    tags = merge({ Name = "${var.name}-http" }, var.tags)
  }
}

# ---------------------------------------------------------------------------- #
# Access the EC2 instance with strongDM over SSH
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "ssh_ec2" {
  ssh_cert {
    name     = "${var.name}-ssh-al2023"
    username = "ec2-user"
    hostname = aws_instance.web_page.private_ip
    port     = 22
    tags     = merge({ Name = "${var.name}-http" }, var.tags)

    proxy_cluster_id = var.proxy_cluster_id
  }
}
