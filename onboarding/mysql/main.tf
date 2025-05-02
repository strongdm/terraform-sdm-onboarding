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
# Local variables to create mysql database
# ---------------------------------------------------------------------------- #

locals {
  username = "strongdmadmin"
  mysql_pw = "strongdmpassword!#123#!"
  mysql_pw_wo = "1"
  database = "strongdmdb"
}

# ---------------------------------------------------------------------------- #
# Create RDS mysql instance and replica
# ---------------------------------------------------------------------------- #

resource "aws_db_subnet_group" "mysql_subnet" {
  name       = "mysql_subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "mysql_rds" {
  allocated_storage       = 10
  db_name                 = local.database
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = local.username
  password_wo             = local.mysql_pw
  password_wo_version = local.mysql_pw_wo
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.mysql.id]
  db_subnet_group_name    = aws_db_subnet_group.mysql_subnet.name
  backup_retention_period = 1

  tags = merge({ Name = "${var.name}-mysql" }, var.tags)
}

resource "aws_db_instance" "mysql_rds_replica" {
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  password_wo            = local.mysql_pw
  password_wo_version    = local.mysql_pw_wo
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.mysql.id]
  replicate_source_db    = aws_db_instance.mysql_rds.identifier

  tags = merge({ Name = "${var.name}-mysql-replica" }, var.tags)
}

resource "aws_security_group" "mysql" {
  name_prefix = "${var.name}-mysql"
  description = "allow inbound from strongDM gateway"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.name}-mysql" }, var.tags)
}

resource "aws_security_group_rule" "allow_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.mysql.id
}

# ---------------------------------------------------------------------------- #
# Add mysql credentials to strongDM
# ---------------------------------------------------------------------------- #

resource "sdm_resource" "mysql_admin" {
  mysql {
    name     = "${var.name}-mysql-admin"
    hostname = aws_db_instance.mysql_rds.address
    database = local.database
    username = local.username
    password = local.mysql_pw
    port     = 3306

    proxy_cluster_id = var.proxy_cluster_id

    tags = merge({ Name = "${var.name}-mysql-admin" }, var.tags)
  }
}

resource "sdm_resource" "mysql_ro" {
  mysql {
    name     = "${var.name}-mysql-replica-read-only"
    hostname = aws_db_instance.mysql_rds_replica.address
    database = local.database
    username = local.username
    password = local.mysql_pw
    port     = 3306

    proxy_cluster_id = var.proxy_cluster_id

    tags = merge({
      Name               = "${var.name}-mysql-ro",
      ReadOnlyOnboarding = "true"
    }, var.tags)
  }
}
