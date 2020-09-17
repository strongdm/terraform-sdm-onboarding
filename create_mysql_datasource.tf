# ---------------------------------------------------------------------------- #
# Local variables to create mysql database
# ---------------------------------------------------------------------------- #
locals {
  username    = "strongdmadmin"
  username_ro = "strongdmreadonly"
  mysql_pw    = "strongdmpassword123!@#"
  database    = "strongdmdb"
  mysql_user_data = <<-USERDATA
  #!/bin/bash

  # add sdm public key
  cat <<SDM_KEY | tee /etc/ssh/sdm_ca.pub
  ${data.sdm_ssh_ca_pubkey.this_key.public_key}
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
  count         = var.create_mysql ? 1 : 0
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}
resource "aws_instance" "mysql" {
  count         = var.create_mysql ? 1 : 0
  ami           = data.aws_ami.ubuntu[0].id
  instance_type = "t3.small"

  subnet_id = local.subnet_ids[0]
  
  user_data = local.mysql_user_data

  tags = merge({ Name = "${var.prefix}-mysql" }, local.default_tags, var.tags)
}

# ---------------------------------------------------------------------------- #
# Add mysql credentials to strongDM
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "mysql_admin" {
  count = var.create_mysql ? 1 : 0
  mysql {
    name     = "${var.prefix}-mysql-admin"
    hostname = aws_instance.mysql[0].private_dns
    database = local.database
    username = local.username
    password = local.mysql_pw
    port     = 3306

    tags = merge({ Name = "${var.prefix}-mysql-admin" }, local.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "admin_grant_mysql_admin" {
  count = var.create_mysql ? 1 : 0
  role_id = sdm_role.admins.id
  resource_id = sdm_resource.mysql_admin[0].id
}
resource "sdm_resource" "mysql_ro" {
  count = var.create_mysql ? 1 : 0
  mysql {
    name     = "${var.prefix}-mysql-read-only"
    hostname = aws_instance.mysql[0].private_dns
    database = local.database
    username = local.username_ro
    password = local.mysql_pw
    port     = 3306

    tags = merge({ Name = "${var.prefix}-mysql-ro" }, local.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "read_only_grant_mysql_ro" {
  count = var.create_mysql ? 1 : 0
  role_id = sdm_role.read_only.id
  resource_id = sdm_resource.mysql_ro[0].id
}
# ---------------------------------------------------------------------------- #
# Access the EC2 instance with strongDM over SSH
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "mysql_ssh" {
  count = var.create_mysql ? 1 : 0
  ssh_cert {
    # dependant on https://github.com/strongdm/issues/issues/1701
    name     = "${var.prefix}-mysql-ssh"
    username = "ubuntu"
    hostname = aws_instance.mysql[0].private_dns
    port     = 22
    tags     = merge({ Name = "${var.prefix}-mysql-ssh" }, local.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "admin_grant_mysql_ssh" {
  count = var.create_mysql ? 1 : 0
  role_id = sdm_role.admins.id
  resource_id = sdm_resource.mysql_ssh[0].id
}