# =============================================================================
# WINDOWS SERVER MODULE VARIABLES
# =============================================================================
# Variable definitions for the Windows Server module. This module creates
# a Windows Server 2022 EC2 instance with RDP access through StrongDM for
# testing and demonstration of Windows-based applications and services.
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE IDENTIFICATION
# -----------------------------------------------------------------------------

variable "name" {
  description = <<-EOT
    Base name for Windows Server resources and StrongDM resource registration.
    Used to create consistent naming across EC2 instances, security groups, key pairs, and StrongDM resources.
    
    Resources created:
    - EC2 instance: "[name]-rdp"
    - Security group: "[name]-rdp-sg"
    - Key pair: "[name]-terraform-key"
    - StrongDM RDP resource: "[name]-rdp"
    
    Example: "terraform-sdm" creates instance "terraform-sdm-rdp"
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
    Map of tags to apply to all Windows Server resources.
    Used for cost tracking, resource organization, and access control policies.
    
    Common tags to include:
    - Environment (production, staging, development)
    - Team or application ownership  
    - Cost center for billing allocation
    - Server purpose or application type
    
    Example: {
      Environment = "development"
      Team        = "windows-admin"
      Project     = "app-testing"
      Purpose     = "development"
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
    StrongDM proxy cluster ID for routing RDP connections to the Windows Server.
    This determines which proxy cluster will handle remote desktop connections.
    
    The proxy cluster must have network connectivity to the VPC subnet
    where the Windows Server is deployed.
    
    Obtained from the StrongDM proxy cluster module output.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# NETWORKING CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = <<-EOT
    ID of the VPC where the Windows Server will be deployed.
    The VPC must have proper DNS settings and internet connectivity for Windows Updates.
    
    Requirements:
    - enableDnsHostnames: true
    - enableDnsSupport: true
    - NAT gateway or internet gateway for Windows Updates and software downloads
    - Adequate IP address space in the subnet
  EOT
  type        = string
}

variable "subnet_id" {
  description = <<-EOT
    ID of the private subnet where the Windows Server will be deployed.
    Private subnet is recommended for security - server has no direct internet access.
    
    Requirements:
    - Must be in the VPC specified by vpc_id
    - Should be a private subnet for enhanced security
    - Must have route to NAT gateway for outbound internet access (Windows Updates)
    - Adequate IP address space for the EC2 instance
    - Proper routing to allow StrongDM proxy connectivity
    
    Example: "subnet-12345678"
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# SECURITY CONFIGURATION
# -----------------------------------------------------------------------------

variable "security_group" {
  description = <<-EOT
    ID of the security group assigned to StrongDM proxy workers.
    This security group will be granted RDP access to the Windows Server on port 3389.
    
    The Windows Server's security group will allow inbound connections from this security group,
    implementing network-level access control and the principle of least privilege.
    
    Connection flow: User → StrongDM Proxy → Windows Server (RDP)
    
    Port allowed:
    - Port 3389: Remote Desktop Protocol (RDP) access
  EOT
  type        = string
}
