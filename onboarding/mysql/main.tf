terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = ">= 3.0.0"
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 4.0.0"
    }
  }
}

# ---------------------------------------------------------------------------- #
# Local variables to create mysql database
# ---------------------------------------------------------------------------- #

locals {
  username        = "strongdmadmin"
  username_ro     = "strongdmreadonly"
  mysql_pw        = "strongdmpassword123!@#"
  database        = "strongdmdb"
  table_name      = "strongdm_table"
}

# ---------------------------------------------------------------------------- #
# Create EC2 instance with mysql bootstrap script
# ---------------------------------------------------------------------------- #

data "aws_ami" "ubuntu" {
  count       = var.create_ssh ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_security_group" "mysql" {
  count       = var.create_ssh ? 1 : 0
  name_prefix = "${var.prefix}-mysql"
  description = "allow inbound from strongDM gateway"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.prefix}-mysql" }, var.default_tags, var.tags)
}

resource "aws_security_group_rule" "allow_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.mysql[0].id
}

resource "aws_security_group_rule" "allow_mysql_ssh" {
  count                    = var.create_ssh ? 1 : 0
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.mysql[0].id
}

resource "aws_instance" "mysql" {
  count                  = var.create_ssh ? 1 : 0
  ami                    = data.aws_ami.ubuntu[0].id
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.mysql[0].id]
  subnet_id              = var.subnet_ids[0]
  user_data              = templatefile("${path.module}/templates/mysql_install/mysql_install.tftpl", { SSH_PUB_KEY = "${var.ssh_pubkey}", MYSQL_ADMIN = "${local.username}", MYSQL_RO = "${local.username_ro}", MYSQL_PW = "${local.mysql_pw}", MYSQL_DB = "${local.database}", MYSQL_TABLE = "${local.table_name}"})
  tags                   = merge({ Name = "${var.prefix}-mysql" }, var.default_tags, var.tags)
}

# ---------------------------------------------------------------------------- #
# Add mysql credentials to strongDM
# ---------------------------------------------------------------------------- #

resource "sdm_resource" "mysql_admin" {
  mysql {
    name     = "${var.prefix}-mysql-admin"
    hostname = aws_instance.mysql[0].private_ip
    database = local.database
    username = local.username
    password = local.mysql_pw
    port     = 3306

    tags = merge({ Name = "${var.prefix}-mysql-admin" }, var.default_tags, var.tags)
  }
}

resource "sdm_resource" "mysql_ro" {
  mysql {
    name     = "${var.prefix}-mysql-read-only"
    hostname = aws_instance.mysql[0].private_ip
    database = local.database
    username = local.username_ro
    password = local.mysql_pw
    port     = 3306

    tags = merge({ Name = "${var.prefix}-mysql-ro" }, var.default_tags, var.tags)
  }
}

# ---------------------------------------------------------------------------- #
# Access the EC2 instance with strongDM over SSH
# ---------------------------------------------------------------------------- #

resource "sdm_resource" "mysql_ssh" {
  count = var.create_ssh ? 1 : 0
  ssh_cert {
    # dependant on https://github.com/strongdm/issues/issues/1701
    name     = "${var.prefix}-ssh-ubuntu"
    username = "ubuntu"
    hostname = aws_instance.mysql[0].private_ip
    port     = 22
    tags     = merge({ Name = "${var.prefix}-mysql-ssh" }, var.default_tags, var.tags)
  }
}

