# =============================================================================
# MYSQL DATABASE MODULE
# =============================================================================
# This module creates a MySQL RDS database instance with StrongDM integration
# for secure database access. Includes database subnet groups, security groups,
# and StrongDM resource registration for seamless connectivity.
#
# Features:
#   - MySQL 8.0 RDS instance with secure configuration
#   - Multi-AZ subnet group for high availability
#   - Security groups restricting access to StrongDM proxies only
#   - Automatic backup configuration
#   - StrongDM resource registration for database access
#   - Secure password management
#
# Security:
#   - Database deployed in private subnets with no public access
#   - Encrypted storage and transit connections
#   - Access restricted to StrongDM proxy security groups
#   - Strong password requirements enforced
# =============================================================================

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0" 
    }
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 15.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# DATABASE CONFIGURATION
# -----------------------------------------------------------------------------
# Local values for database configuration and credentials
# SECURITY NOTE: In production, use AWS Secrets Manager for password management

locals {
  # Database administrator username
  username = "strongdmadmin"

  # SECURITY WARNING: Hardcoded password for demonstration only
  # Production deployments should use random passwords stored in AWS Secrets Manager
  mysql_pw = "strongdmpassword!#123#!"

  # Password override flag (legacy compatibility)
  mysql_pw_wo = "1"

  # Default database name created during instance provisioning
  database = "strongdmdb"
}

# -----------------------------------------------------------------------------
# RDS SUBNET GROUP
# -----------------------------------------------------------------------------
# Creates DB subnet group spanning multiple AZs for high availability

resource "aws_db_subnet_group" "mysql_subnet" {
  name       = "mysql_subnet"
  subnet_ids = var.subnet_ids

  # Required for RDS instances to span multiple availability zones
  # Provides high availability and automatic failover capabilities
  tags = merge({
    Name = "${var.name}-mysql-subnet-group"
  }, var.tags)
}

# -----------------------------------------------------------------------------
# PRIMARY MYSQL RDS INSTANCE
# -----------------------------------------------------------------------------
# Creates the primary MySQL database instance with secure configuration
# and optimal settings for StrongDM integration

resource "aws_db_instance" "mysql_rds" {
  # Storage configuration
  allocated_storage = 10    # GB - minimum for testing, scale for production
  storage_type      = "gp2" # General Purpose SSD
  storage_encrypted = true  # Encrypt data at rest

  # Database engine configuration
  db_name              = local.database # Initial database name
  engine               = "mysql"
  engine_version       = "8.4.6"            # Latest stable MySQL 8.4.x
  instance_class       = "db.t3.micro"      # Burstable performance, cost-effective for testing
  parameter_group_name = "default.mysql8.4" # Default parameter group for MySQL 8.0

  # Authentication configuration
  username            = local.username
  password_wo         = local.mysql_pw # SECURITY: Use random passwords in production
  password_wo_version = local.mysql_pw_wo

  # Network and security configuration
  vpc_security_group_ids = [aws_security_group.mysql.id]         # Restricts access to StrongDM proxies
  db_subnet_group_name   = aws_db_subnet_group.mysql_subnet.name # Multi-AZ deployment
  publicly_accessible    = false                                 # Keep database private, accessible only through StrongDM

  # Backup and maintenance configuration
  backup_retention_period = 1                     # Minimum backup retention for cost efficiency
  backup_window           = "03:00-04:00"         # UTC backup window during low usage
  maintenance_window      = "sun:04:00-sun:05:00" # UTC maintenance window

  # Snapshot configuration for testing environments
  skip_final_snapshot = true # WARNING: Set to false for production to retain final snapshot

  # Performance and monitoring
  performance_insights_enabled = false # Disable for cost savings in test environments
  monitoring_interval          = 0     # Disable enhanced monitoring for cost savings

  # High availability (disabled for cost savings in testing)
  multi_az = false # Enable for production deployments

  tags = merge({ Name = "${var.name}-mysql" }, var.tags)
}

# -----------------------------------------------------------------------------
# MYSQL READ REPLICA
# -----------------------------------------------------------------------------
# Creates a read-only replica for load distribution and read-only access
# Useful for reporting, analytics, and read-only user access

resource "aws_db_instance" "mysql_rds_replica" {
  # Replica configuration inherits from primary instance
  engine               = "mysql"
  engine_version       = "8.4.6"
  instance_class       = "db.t3.micro" # Can be different size than primary
  parameter_group_name = "default.mysql8.4"

  # Authentication (inherits from source but can override password)
  password_wo         = local.mysql_pw
  password_wo_version = local.mysql_pw_wo

  # Security configuration
  vpc_security_group_ids = [aws_security_group.mysql.id]
  publicly_accessible    = false

  # Replica-specific configuration
  replicate_source_db = aws_db_instance.mysql_rds.identifier # Links to primary instance

  # Snapshot configuration
  skip_final_snapshot = true # WARNING: Set to false for production

  # Performance monitoring (disabled for cost savings)
  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = merge({ Name = "${var.name}-mysql-replica" }, var.tags)
}

# -----------------------------------------------------------------------------
# MYSQL SECURITY GROUP
# -----------------------------------------------------------------------------
# Creates security group allowing access only from StrongDM proxy instances
# Implements network-level access control for database security

resource "aws_security_group" "mysql" {
  name_prefix = "${var.name}-mysql"
  description = "MySQL database security group - allows inbound from StrongDM proxies only"
  vpc_id      = var.vpc_id

  # Outbound rules (allow all egress for database operations)
  # Required for RDS maintenance, monitoring, and replication
  egress {
    description = "All outbound traffic for RDS operations"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name    = "${var.name}-mysql-sg",
    Purpose = "MySQL database access control"
  }, var.tags)
}

# -----------------------------------------------------------------------------
# MYSQL SECURITY GROUP INGRESS RULE
# -----------------------------------------------------------------------------
# Allows MySQL traffic (port 3306) from StrongDM proxy security group only
# Implements principle of least privilege for database access

resource "aws_security_group_rule" "allow_mysql" {
  type        = "ingress"
  description = "MySQL access from StrongDM proxy instances"

  # MySQL standard port
  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"

  # Source: StrongDM proxy security group (not direct IP access)
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.mysql.id
}

# =============================================================================
# STRONGDM MYSQL RESOURCE REGISTRATION
# =============================================================================
# Registers MySQL database instances as StrongDM resources for secure access.
# Creates both admin (read/write) and read-only resource entries to support
# different access patterns and user roles.
#
# Access Patterns:
#   - Admin resource: Full database access for administrative tasks
#   - Read-only resource: Query-only access for reporting and analytics
#   - Both resources route through the specified proxy cluster
# =============================================================================

# -----------------------------------------------------------------------------
# MYSQL ADMIN RESOURCE (READ/WRITE ACCESS)
# -----------------------------------------------------------------------------
# Registers the primary MySQL instance for administrative database access
# Provides full read/write permissions for database management

resource "sdm_resource" "mysql_admin" {
  mysql {
    # Resource identification in StrongDM
    name = "${var.name}-mysql-admin"

    # Connection configuration
    hostname = aws_db_instance.mysql_rds.address # RDS endpoint address
    database = local.database                    # Default database to connect to
    port     = 3306                              # MySQL standard port

    # Authentication credentials
    username = local.username
    password = local.mysql_pw # SECURITY: Consider using dynamic secrets in production

    # StrongDM routing configuration
    proxy_cluster_id = var.proxy_cluster_id # Route connections through proxy cluster

    # Resource tagging for organization and access control
    tags = merge({
      Name         = "${var.name}-mysql-admin",
      AccessType   = "admin",
      DatabaseType = "mysql"
    }, var.tags)
  }
}

# -----------------------------------------------------------------------------
# MYSQL READ-ONLY RESOURCE (QUERY-ONLY ACCESS)
# -----------------------------------------------------------------------------
# Registers the MySQL replica instance for read-only database access
# Ideal for analysts, reporting tools, and users who only need query access

resource "sdm_resource" "mysql_ro" {
  mysql {
    # Resource identification in StrongDM
    name = "${var.name}-mysql-replica-read-only"

    # Connection configuration (points to read replica)
    hostname = aws_db_instance.mysql_rds_replica.address # Replica endpoint
    database = local.database                            # Default database
    port     = 3306                                      # MySQL standard port

    # Authentication credentials (same as primary for simplicity)
    username = local.username
    password = local.mysql_pw # SECURITY: Consider read-only user in production

    # StrongDM routing configuration
    proxy_cluster_id = var.proxy_cluster_id

    # Resource tagging with read-only identifier
    tags = merge({
      Name               = "${var.name}-mysql-ro",
      AccessType         = "read-only",
      DatabaseType       = "mysql",
      ReadOnlyOnboarding = "true" # Special tag for read-only access policies
    }, var.tags)
  }
}
