terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = ">= 3.0.0"
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 1.0.15"
    }
    tls = ">= 3.0.0"
  }
}

# ---------------------------------------------------------------------------- #
# Generate an RSA key pair to encrypt and decrypt the Windows password
# ---------------------------------------------------------------------------- #

resource "tls_private_key" "windows_server" {
  # This resource is not recommended for production environements
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "windows_key" {
  key_name   = "${var.prefix}-terraform-key"
  public_key = tls_private_key.windows_server.public_key_openssh
}

# ---------------------------------------------------------------------------- #
# Create a Security Group to allow RDP communication with the server
# ---------------------------------------------------------------------------- #

resource "aws_security_group" "windows_server" {
  name_prefix = "${var.prefix}-windows-server"
  description = "allows 3389"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [var.security_group]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ Name = "${var.prefix}-rdp" }, var.default_tags, var.tags)
}

# ---------------------------------------------------------------------------- #
# Lookup the latest Windows Server 2016 AMI and generate an EC2 instance
# ---------------------------------------------------------------------------- #

data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base*"]
  }
}

resource "aws_instance" "windows_server" {
  ami           = data.aws_ami.windows_server.image_id
  instance_type = "t3a.medium"

  subnet_id              = var.subnet_ids
  vpc_security_group_ids = [aws_security_group.windows_server.id]

  get_password_data = true
  key_name          = aws_key_pair.windows_key.key_name
  # This key is used to encrypt the windows password

  tags = merge({ Name = "${var.prefix}-rdp" }, var.default_tags, var.tags)
}

# ---------------------------------------------------------------------------- #
# Add credentials to strongDM
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "windows_server" {
  rdp {
    name     = "${var.prefix}-rdp"
    hostname = aws_instance.windows_server.private_ip
    port     = 3389
    username = "Administrator"
    password = rsadecrypt(aws_instance.windows_server.password_data, tls_private_key.windows_server.private_key_pem)
    tags     = merge({ Name = "${var.prefix}-rdp" }, var.default_tags, var.tags)
  }
}

