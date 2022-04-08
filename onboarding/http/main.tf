terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = ">= 3.0.0"
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 1.0.15"
    }
  }
}

# ---------------------------------------------------------------------------- #
# Create an EC2 instance
# ---------------------------------------------------------------------------- #
data "aws_ami" "amazon_linux_2" {
  count       = var.create_ssh ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
resource "aws_security_group" "web_page" {
  count       = var.create_ssh ? 1 : 0
  name_prefix = "${var.prefix}-web-page"
  description = "allow inbound from strongDM gateway"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.prefix}-http" }, var.default_tags, var.tags)
}
resource "aws_security_group_rule" "allow_80" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.web_page[0].id
}
resource "aws_security_group_rule" "allow_http_ssh" {
  count                    = var.create_ssh ? 1 : 0
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.web_page[0].id
}
resource "aws_instance" "web_page" {
  count         = var.create_ssh ? 1 : 0
  ami           = data.aws_ami.amazon_linux_2[0].id
  instance_type = "t3.micro"

  subnet_id              = var.subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.web_page[0].id]

  # Configures a simple HTTP web page 
  user_data = templatefile("${path.module}/templates/http_install/http_install.tftpl", { SSH_PUB_KEY = "${var.ssh_pubkey}" }) 
  tags = merge({ Name = "${var.prefix}-http" }, var.default_tags, var.tags)
}
# ---------------------------------------------------------------------------- #
# Add the web page to strongDM
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "web_page" {
  http_no_auth {
    name             = "${var.prefix}-http"
    url              = "http://${aws_instance.web_page[0].private_ip}"
    default_path     = "/phpinfo.php"
    healthcheck_path = "/phpinfo.php"
    subdomain        = "simple-web-page"

    tags = merge({ Name = "${var.prefix}-http" }, var.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "admin_grant_web_page" {
  role_id     = var.admins_id
  resource_id = sdm_resource.web_page.id
}
resource "sdm_role_grant" "read_only_grant_web_page" {
  role_id     = var.read_only_id
  resource_id = sdm_resource.web_page.id
}
# ---------------------------------------------------------------------------- #
# Access the EC2 instance with strongDM over SSH
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "ssh_ec2" {
  count = var.create_ssh ? 1 : 0
  ssh_cert {
    # dependant on https://github.com/strongdm/issues/issues/1701
    name     = "${var.prefix}-ssh-amzn2"
    username = "ec2-user"
    hostname = aws_instance.web_page[0].private_ip
    port     = 22
    tags     = merge({ Name = "${var.prefix}-http" }, var.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "admin_grant_ssh_ec2" {
  count       = var.create_ssh ? 1 : 0
  role_id     = var.admins_id
  resource_id = sdm_resource.ssh_ec2[0].id
}