# =============================================================================
# MYSQL MODULE VARIABLES
# =============================================================================
# Variable definitions for the MySQL database module. This module creates
# MySQL RDS instances with read replicas and StrongDM integration for secure
# database access through the proxy network.
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE IDENTIFICATION
# -----------------------------------------------------------------------------

variable "name" {
  description = <<-EOT
    Base name for MySQL database resources and StrongDM resource registration.
    Used to create consistent naming across RDS instances, security groups, and StrongDM resources.
    
    Resources created:
    - RDS instance: "[name]-mysql"
    - Read replica: "[name]-mysql-replica"  
    - Security group: "[name]-mysql-sg"
    - StrongDM admin resource: "[name]-mysql-admin"
    - StrongDM read-only resource: "[name]-mysql-replica-read-only"
    
    Example: "terraform-sdm" creates RDS instance "terraform-sdm-mysql"
  EOT
  type        = string
  default     = "strongDM"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.name))
    error_message = "Name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "tags" {
  description = <<-EOT
    Map of tags to apply to all MySQL database resources.
    These tags are used for cost tracking, resource organization, and access control policies.
    
    Common tags to include:
    - Environment (production, staging, development)
    - Team or application ownership
    - Cost center for billing allocation  
    - Data classification level
    
    Example: {
      Environment = "production"
      Team        = "data"
      Project     = "analytics"
      DataClass   = "internal"
    }
  EOT
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# STRONGDM INTEGRATION CONFIGURATION
# -----------------------------------------------------------------------------

variable "proxy_cluster_id" {
  description = <<-EOT
    StrongDM proxy cluster ID for routing database connections.
    This determines which proxy cluster will handle MySQL database connections.
    
    The proxy cluster must have network connectivity to the VPC subnets
    where the MySQL RDS instances are deployed.
    
    Obtained from the StrongDM proxy cluster module output.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------  
# NETWORKING CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = <<-EOT
    ID of the VPC where MySQL RDS instances will be deployed.
    The VPC must have proper DNS settings and internet connectivity for RDS operations.
    
    Requirements:
    - enableDnsHostnames: true
    - enableDnsSupport: true
    - Internet gateway or NAT gateway for RDS maintenance and monitoring
    - Adequate IP address space in subnets
  EOT
  type        = string
}

variable "subnet_ids" {
  description = <<-EOT
    List of private subnet IDs for MySQL RDS deployment.
    Subnets should span multiple Availability Zones for high availability and automatic failover.
    
    Requirements:
    - Minimum 2 subnets in different AZs (required by RDS)
    - Private subnets recommended for security (no direct internet access)
    - NAT gateway access for RDS maintenance operations
    - Adequate IP address space for RDS instances
    - Proper routing to allow StrongDM proxy connectivity
    
    Example: ["subnet-12345678", "subnet-87654321"]
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided for RDS high availability across AZs."
  }
}

# -----------------------------------------------------------------------------
# SECURITY CONFIGURATION
# -----------------------------------------------------------------------------

variable "security_group" {
  description = <<-EOT
    ID of the security group assigned to StrongDM proxy workers.
    This security group will be granted access to the MySQL instances on port 3306.
    
    The MySQL security group will allow inbound connections from this security group,
    implementing network-level access control and the principle of least privilege.
    
    This creates a secure connection path: User → StrongDM Proxy → MySQL Database
  EOT
  type        = string
}
