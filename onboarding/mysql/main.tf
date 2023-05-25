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
  mysql_pw        = "strongdmpassword!#123#!"
  database        = "strongdmdb"
  table_name      = "strongdm_table"
}

# ---------------------------------------------------------------------------- #
# Create RDS mysql instance and replica
# ---------------------------------------------------------------------------- #

resource "aws_db_subnet_group" "mysql_subnet" {
  name       = "mysql_subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "msyql_rds" {
  allocated_storage    = 10
  db_name              = local.database
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = local.username
  password             = local.mysql_pw
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.mysql[0].id]
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet.name
  backup_retention_period = 1

  tags = merge({ Name = "${var.prefix}-mysql" }, var.default_tags, var.tags)
}

resource "aws_db_instance" "msyql_rds_replica" {
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  password               = local.mysql_pw
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.mysql[0].id]
  replicate_source_db    = aws_db_instance.msyql_rds.id

  tags = merge({ Name = "${var.prefix}-mysql-replica" }, var.default_tags, var.tags)
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

# ---------------------------------------------------------------------------- #
# Add mysql credentials to strongDM
# ---------------------------------------------------------------------------- #

resource "sdm_resource" "mysql_admin" {
  mysql {
    name     = "${var.prefix}-mysql-admin"
    hostname = aws_db_instance.msyql_rds.address
    database = local.database
    username = local.username
    password = local.mysql_pw
    port     = 3306

    tags = merge({ Name = "${var.prefix}-mysql-admin" }, var.default_tags, var.tags)
  }
}

resource "sdm_resource" "mysql_ro" {
  mysql {
    name     = "${var.prefix}-mysql-replica-read-only"
    hostname = aws_db_instance.msyql_rds_replica.address
    database = local.database
    username = local.username
    password = local.mysql_pw
    port     = 3306

    tags = merge({ 
      Name = "${var.prefix}-mysql-ro",
      ReadOnlyOnboarding = "true"
    }, var.default_tags, var.tags)
  }
}
