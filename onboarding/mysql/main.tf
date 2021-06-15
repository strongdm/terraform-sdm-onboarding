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
# Local variables to create mysql database
# ---------------------------------------------------------------------------- #

locals {
  username        = "strongdmadmin"
  username_ro     = "strongdmreadonly"
  mysql_pw        = "strongdmpassword123!@#"
  database        = "strongdmdb"
  table_name      = "strongdm_table"
  mysql_user_data = <<-USERDATA
  #!/bin/bash

  # add sdm public key
  cat <<SDM_KEY | tee /etc/ssh/sdm_ca.pub
  ${var.ssh_pubkey}
  SDM_KEY
  cat <<SDM_TRUST | sudo tee -a /etc/ssh/sshd_config
  TrustedUserCAKeys /etc/ssh/sdm_ca.pub
  SDM_TRUST
  systemctl restart sshd

  # setup mysql
  sudo apt update -y 
  sudo apt install -y mysql-server
  sudo mysql_secure_installation <<EOF
  n
  ${local.mysql_pw}
  ${local.mysql_pw}
  y
  n
  y
  y
  EOF
  sudo mysql --user=root \
    --password=${local.mysql_pw} \
    --execute="CREATE DATABASE ${local.database};\
    CREATE TABLE ${local.database}.${local.table_name} (message VARCHAR(20));\
    INSERT INTO ${local.database}.${local.table_name} VALUES ('Hello');\
    CREATE USER '${local.username}'@'%' IDENTIFIED BY '${local.mysql_pw}';\
    GRANT ALL PRIVILEGES ON *.* TO '${local.username}'@'%';\
    CREATE USER '${local.username_ro}'@'%' IDENTIFIED BY '${local.mysql_pw}';\
    GRANT SELECT ON ${local.database}.* TO '${local.username_ro}'@'%';\
    FLUSH PRIVILEGES;"
  sudo sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
  sudo systemctl restart mysql
  USERDATA
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
  user_data              = local.mysql_user_data
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

resource "sdm_role_grant" "admin_grant_mysql_admin" {
  role_id     = var.admins_id
  resource_id = sdm_resource.mysql_admin.id
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

resource "sdm_role_grant" "read_only_grant_mysql_ro" {
  role_id     = var.read_only_id
  resource_id = sdm_resource.mysql_ro.id
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

resource "sdm_role_grant" "admin_grant_mysql_ssh" {
  count       = var.create_ssh ? 1 : 0
  role_id     = var.admins_id
  resource_id = sdm_resource.mysql_ssh[0].id
}
