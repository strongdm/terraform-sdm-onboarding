# =============================================================================
# HTTP/SSH MODULE VARIABLES
# =============================================================================
# Variable definitions for the HTTP/SSH resources module. This module creates
# a Linux EC2 instance with web server and SSH access through StrongDM for
# testing and demonstration purposes.
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE IDENTIFICATION
# -----------------------------------------------------------------------------

variable "name" {
  description = <<-EOT
    Base name for HTTP/SSH server resources and StrongDM resource registration.
    Used to create consistent naming across EC2 instances, security groups, and StrongDM resources.
    
    Resources created:
    - EC2 instance: "[name]-http"
    - Security group: "[name]-http-sg"
    - StrongDM HTTP resource: "[name]-http"
    - StrongDM SSH resource: "[name]-ssh-al2023"
    
    Example: "terraform-sdm" creates instance "terraform-sdm-http"
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
    Map of tags to apply to all HTTP/SSH server resources.
    Used for cost tracking, resource organization, and access control policies.
    
    Common tags to include:
    - Environment (production, staging, development)  
    - Team or application ownership
    - Cost center for billing allocation
    - Server purpose or application type
    
    Example: {
      Environment = "development"
      Team        = "frontend"
      Project     = "web-demo"
      Purpose     = "testing"
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
    StrongDM proxy cluster ID for routing HTTP and SSH connections.
    This determines which proxy cluster will handle web and shell access to the server.
    
    The proxy cluster must have network connectivity to the VPC subnet
    where the HTTP/SSH server is deployed.
    
    Obtained from the StrongDM proxy cluster module output.
  EOT
  type        = string
}

variable "ssh_pubkey" {
  description = <<-EOT
    StrongDM SSH Certificate Authority public key for SSH authentication.
    This public key is installed on the EC2 instance to enable certificate-based SSH access.
    
    The key is automatically retrieved from your StrongDM organization and allows
    users to SSH to the instance using StrongDM-issued certificates instead of
    traditional SSH key pairs.
    
    Security benefits:
    - No need to manage individual SSH keys
    - Automatic key rotation and revocation
    - Audit trail of all SSH access
    - Centralized access control through StrongDM
    
    Obtained from data.sdm_ssh_ca_pubkey.this_key.public_key
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# NETWORKING CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = <<-EOT
    ID of the VPC where the HTTP/SSH server will be deployed.
    The VPC must have proper DNS settings and internet connectivity for package installations.
    
    Requirements:
    - enableDnsHostnames: true
    - enableDnsSupport: true  
    - NAT gateway or internet gateway for package downloads
    - Adequate IP address space in the subnet
  EOT
  type        = string
}

variable "subnet_id" {
  description = <<-EOT
    ID of the private subnet where the HTTP/SSH server will be deployed.
    Private subnet is recommended for security - server has no direct internet access.
    
    Requirements:
    - Must be in the VPC specified by vpc_id
    - Should be a private subnet for enhanced security
    - Must have route to NAT gateway for outbound internet access
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
    This security group will be granted access to the HTTP/SSH server on ports 80 and 22.
    
    The server's security group will allow inbound connections from this security group,
    implementing network-level access control and the principle of least privilege.
    
    Connection flow: User → StrongDM Proxy → HTTP/SSH Server
    
    Ports allowed:
    - Port 80: HTTP web server access
    - Port 22: SSH shell access
  EOT
  type        = string
}
