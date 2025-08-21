# =============================================================================
# STRONGDM ONBOARDING MODULE VARIABLES
# =============================================================================
# Variable definitions for the main StrongDM onboarding module.
# These variables control resource creation, networking, access control,
# and tagging for the entire StrongDM infrastructure deployment.
# =============================================================================

# -----------------------------------------------------------------------------
# GLOBAL CONFIGURATION
# -----------------------------------------------------------------------------

variable "tags" {
  description = <<-EOT
    Map of tags to apply to all AWS and StrongDM resources.
    Used for cost tracking, resource organization, and compliance.
    
    Example: {
      Environment = "production"
      Team        = "platform" 
      Project     = "strongdm-onboarding"
      CostCenter  = "security"
    }
  EOT
  type        = map(string)
  default     = {}
}

variable "region" {
  description = <<-EOT
    AWS region where all resources will be deployed.
    Choose a region close to your users for optimal performance.
    
    Popular regions: us-west-2, us-east-1, eu-west-1
  EOT
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-west-2)."
  }
}

variable "name" {
  description = <<-EOT
    Base name prefix for all resources created by this module.
    Used to ensure consistent naming across AWS and StrongDM resources.
    
    Example: "terraform-sdm" creates resources like:
    - EKS cluster: "terraform-sdm-eks"
    - MySQL database: "terraform-sdm-mysql"  
    - VPC: "terraform-sdm-vpc"
  EOT
  type        = string
  default     = "strongdm"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.name))
    error_message = "Name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

# -----------------------------------------------------------------------------
# RESOURCE CREATION TOGGLES
# -----------------------------------------------------------------------------

variable "create_eks" {
  description = <<-EOT
    Controls creation of Amazon EKS cluster with StrongDM integration.
    
    When enabled, creates:
    - EKS cluster with Kubernetes 1.33
    - Cluster security groups and IAM roles
    - StrongDM resource registration for kubectl access
    - Integration with StrongDM proxy for secure connectivity
    
    Estimated provisioning time: ~20 minutes
  EOT
  type        = bool
  default     = false
}

variable "create_mysql" {
  description = <<-EOT
    Controls creation of MySQL RDS database with StrongDM integration.
    
    When enabled, creates:
    - RDS MySQL 8.4.6 instance with secure configuration
    - Database subnet group across multiple AZs
    - Security groups for StrongDM proxy access
    - StrongDM resource registration for database access
    - MySQL read replica for load distribution
    
    Estimated provisioning time: ~15 minutes
  EOT
  type        = bool
  default     = true
}

variable "create_rdp" {
  description = <<-EOT
    Controls creation of Windows Server EC2 instance with RDP access via StrongDM.
    
    When enabled, creates:
    - Windows Server 2022 EC2 instance
    - Security groups allowing StrongDM proxy access
    - StrongDM RDP resource registration
    - Automatic password generation for Administrator account
    - Private subnet deployment for enhanced security
    
    Estimated provisioning time: ~10 minutes
  EOT
  type        = bool
  default     = false
}

variable "create_http_ssh" {
  description = <<-EOT
    Controls creation of Linux server with HTTP and SSH access via StrongDM.
    
    When enabled, creates:
    - Amazon Linux 2023 EC2 instance with web server
    - Security groups for StrongDM proxy connectivity
    - StrongDM HTTP and SSH resource registrations
    - SSH certificate-based authentication setup
    - Sample website deployment for testing
    Estimated provisioning time: ~5 minutes
  EOT
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# NETWORKING CONFIGURATION
# -----------------------------------------------------------------------------

variable "create_vpc" {
  description = <<-EOT
    Controls creation of dedicated VPC infrastructure for StrongDM resources.
    
    When enabled, creates:
    - VPC with DNS hostnames and resolution enabled
    - Public subnets across multiple AZs with internet gateway
    - Private subnets across multiple AZs with NAT gateways
    - Route tables and security group configurations
    - Proper tagging for Kubernetes integration (if EKS enabled)
    
    When disabled:
    - Uses default VPC or explicitly provided vpc_id
    - Requires manual subnet configuration for multi-AZ deployments
    - Less secure as resources may be in public subnets
    
    Estimated provisioning time: ~5 minutes
  EOT
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = <<-EOT
    ID of existing VPC to use when create_vpc = false.
    If specified, you must also provide public_subnet_ids for proper deployment.
    
    Requirements for existing VPC:
    - enableDnsHostnames = true
    - enableDnsSupport = true  
    - Internet gateway attached for public access
    - Adequate IP address space for resource deployment
    
    Example: "vpc-12345678"
  EOT
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = <<-EOT
    List of existing public subnet IDs when using existing VPC.
    These subnets will host NAT gateways and load balancers requiring internet access.
    
    Requirements:
    - Must be in the VPC specified by vpc_id
    - Should span multiple Availability Zones for high availability
    - Must have routes to an Internet Gateway
    - Adequate IP address space for NAT gateways and load balancers
    
    Example: ["subnet-12345678", "subnet-87654321"]
  EOT
  type        = list(string)
  default     = null
}

variable "private_subnet_ids" {
  description = <<-EOT
    List of existing private subnet IDs for resource deployment.
    If not specified, will default to using public_subnet_ids (less secure).
    
    Requirements:
    - Must be in the VPC specified by vpc_id
    - Should span multiple Availability Zones for high availability
    - Should have routes to NAT Gateway for outbound internet access
    - Adequate IP address space for EKS nodes, databases, and EC2 instances
    
    Example: ["subnet-11111111", "subnet-22222222"]
  EOT
  type        = list(string)
  default     = null
}

# -----------------------------------------------------------------------------
# ACCESS CONTROL AND SECURITY
# -----------------------------------------------------------------------------

variable "create_sdm_policy_permit_everything" {
  description = <<-EOT
    Creates a permissive StrongDM access policy for testing purposes.
    
    WARNING: This policy grants access to all resources for all users.
    Only enable this for development/testing environments, never in production.
    
    When enabled:
    - Creates a StrongDM policy that permits all actions
    - Assigns policy to all created resources  
    - Useful for initial testing and proof-of-concept deployments
    
    For production deployments:
    - Set to false and configure granular access policies
    - Use role-based access control through StrongDM Admin UI
    - Follow principle of least privilege
  EOT
  type        = bool
  default     = false
}

variable "grant_to_existing_users" {
  description = <<-EOT
    List of email addresses for existing StrongDM users to grant access to all resources.
    These users must already exist in your StrongDM organization.
    
    When specified, creates StrongDM grants that provide access to:
    - All created resources (EKS, MySQL, RDP, HTTP/SSH)
    - Automatic role assignment based on resource type
    - Immediate access without additional admin approval
    
    Example: ["admin@company.com", "developer@company.com"]
    
    Note: Users not in this list will need manual access grants via StrongDM Admin UI.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.grant_to_existing_users : can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All entries must be valid email addresses."
  }
}

variable "admin_users" {
  description = <<-EOT
    List of email addresses for new StrongDM admin users to create and grant full access.
    These users will be created if they don't exist in your StrongDM organization.
    
    Admin users receive:
    - Full administrative privileges in StrongDM
    - Access to all created resources
    - User management capabilities
    - Policy and role management permissions
    
    Example: ["admin@company.com", "security-admin@company.com"]
    
    SECURITY WARNING: Admin users have extensive privileges. Use sparingly and review regularly.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.admin_users : can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All entries must be valid email addresses."
  }
}

variable "read_only_users" {
  description = <<-EOT
    List of email addresses for new StrongDM read-only users to create.
    These users will be created with limited, view-only access to resources.
    
    Read-only users receive:
    - View access to resource metadata
    - Query-only database permissions (SELECT statements)  
    - SSH access without sudo/admin privileges
    - Cannot modify system configurations
    
    Example: ["analyst@company.com", "auditor@company.com"]
    
    Use cases: Security auditing, compliance reviews, monitoring, reporting.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.read_only_users : can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All entries must be valid email addresses."
  }
}

# -----------------------------------------------------------------------------
# NETWORK SECURITY CONFIGURATION  
# -----------------------------------------------------------------------------

variable "ingress_cidr_blocks" {
  description = <<-EOT
    List of CIDR blocks allowed to connect to StrongDM proxy ingress points.
    Controls which IP ranges can establish connections to StrongDM proxies.
    
    Default allows global access (0.0.0.0/0) for initial testing.
    
    Production recommendations:
    - Corporate network ranges: ["10.0.0.0/8", "172.16.0.0/12"] 
    - Specific office locations: ["203.0.113.0/24", "198.51.100.0/24"]
    - VPN endpoint ranges: ["192.168.1.0/24"]
    
    Security considerations:
    - Smaller CIDR blocks = more restrictive access
    - Consider remote work patterns and VPN usage
    - Monitor CloudTrail logs for access patterns
    - Review and update regularly based on business needs
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.ingress_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All entries must be valid CIDR blocks (e.g., 10.0.0.0/8, 0.0.0.0/0)."
  }
}

# -----------------------------------------------------------------------------
# DEPLOYMENT ARCHITECTURE CONFIGURATION
# -----------------------------------------------------------------------------

variable "use_gateways" {
  description = <<-EOT
    Controls deployment architecture: modern proxy clusters vs legacy gateways.
    
    Proxy Clusters (use_gateways = false, RECOMMENDED):
    - Modern serverless architecture using ECS Fargate
    - Automatic scaling and high availability
    - Reduced operational overhead
    - Better cost efficiency
    - Enhanced security features
    
    Legacy Gateways (use_gateways = true, DEPRECATED):
    - Traditional EC2-based gateway deployment  
    - Manual scaling and maintenance required
    - Higher operational costs
    - Limited to older StrongDM features
    
    Migration note: Existing gateway deployments can be migrated to proxy clusters.
    Contact StrongDM support for migration assistance.
  EOT
  type        = bool
  default     = false
}
