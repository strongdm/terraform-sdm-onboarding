# =============================================================================
# STRONGDM GATEWAY MODULE VARIABLES
# =============================================================================
# Variable definitions for the StrongDM gateway module. This module
# creates traditional EC2-based StrongDM gateways for secure infrastructure access.
#
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE IDENTIFICATION
# -----------------------------------------------------------------------------

variable "sdm_node_name" {
  description = <<-EOT
    Base name for StrongDM gateway resources and AWS infrastructure.
    Used to create consistent naming across EC2 instances, security groups, and StrongDM gateway nodes.
    
    Resources created:
    - EC2 instances: "[name]-gateway-0", "[name]-gateway-1", etc.
    - Security groups: "[name]-gateway-sg"
    - Elastic IPs: "[name]-gateway-eip-0", "[name]-gateway-eip-1", etc.
    - StrongDM nodes: "[name]-gateway-0", "[name]-gateway-1", etc.
    
    Example: "terraform-sdm" creates gateways "terraform-sdm-gateway-0"
  EOT
  type        = string
  default     = "strongDM"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.sdm_node_name))
    error_message = "Gateway name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

# -----------------------------------------------------------------------------
# NETWORKING CONFIGURATION
# -----------------------------------------------------------------------------

variable "deploy_vpc_id" {
  description = <<-EOT
    ID of the VPC where StrongDM gateways will be deployed.
    Used for security group creation and network isolation.
    
    Requirements:
    - enableDnsHostnames: true (for EIP DNS resolution)
    - enableDnsSupport: true
    - Internet gateway attached for public connectivity
    - Adequate IP address space in subnets
  EOT
  type        = string
}

variable "gateway_listen_port" {
  description = <<-EOT
    TCP port number for StrongDM gateways to listen for incoming client connections.
    This port must be accessible from client networks for StrongDM connectivity.
    
    Default: 5000 (StrongDM standard port)
    Range: 1024-65535 (avoid well-known ports below 1024)
    
    Security considerations:
    - Port must be allowed through corporate firewalls
    - Consider using non-standard ports for additional security
    - Ensure port is not conflicting with other services
  EOT
  type        = number
  default     = 5000

  validation {
    condition     = var.gateway_listen_port >= 1024 && var.gateway_listen_port <= 65535
    error_message = "Gateway listen port must be between 1024 and 65535."
  }
}

variable "gateway_subnet_ids" {
  description = <<-EOT
    List of public subnet IDs where StrongDM gateways will be deployed.
    Gateways require public subnets for direct internet connectivity and client access.
    
    Requirements:
    - Must be public subnets with internet gateway routes
    - Should span multiple Availability Zones for high availability
    - Adequate IP address space for gateway instances
    - Network ACLs allowing ingress/egress traffic on gateway ports
    
    High availability recommendation:
    - Use at least 2 subnets in different AZs
    - Each subnet should support at least one gateway instance
    
    Example: ["subnet-12345678", "subnet-87654321"]
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.gateway_subnet_ids) >= 1
    error_message = "At least one gateway subnet ID must be provided."
  }
}

# -----------------------------------------------------------------------------
# SECURITY CONFIGURATION
# -----------------------------------------------------------------------------

variable "gateway_ingress_ips" {
  description = <<-EOT
    List of CIDR blocks allowed to connect to StrongDM gateways.
    Controls which IP ranges can establish connections to gateway instances.
    
    Default allows global access (0.0.0.0/0) for initial testing.
    
    Production recommendations:
    - Corporate network ranges: ["10.0.0.0/8", "172.16.0.0/12"] 
    - Specific office locations: ["203.0.113.0/24", "198.51.100.0/24"]
    - VPN endpoint ranges: ["192.168.1.0/24"]
    - Remote worker IP ranges from ISP allocations
    
    Security considerations:
    - Smaller CIDR blocks = more restrictive access
    - Consider remote work patterns and VPN usage
    - Monitor CloudTrail logs for connection attempts
    - Review and update regularly based on business needs
    - Avoid 0.0.0.0/0 in production environments
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.gateway_ingress_ips : can(cidrhost(cidr, 0))
    ])
    error_message = "All entries must be valid CIDR blocks (e.g., 10.0.0.0/8, 0.0.0.0/0)."
  }
}

# -----------------------------------------------------------------------------
# RELAY CONFIGURATION 
# -----------------------------------------------------------------------------

variable "relay_subnet_ids" {
  description = "relay subnet iDs"
  type        = list(string)
  default     = []
}
variable "ssh_key" {
  description = "Creates EC2 instances with public key for access"
  type        = string
  default     = null
}
variable "ssh_source" {
  description = "Restric SSH access, default is allow from anywahere"
  type        = string
  default     = "0.0.0.0/0"
}
variable "tags" {
  description = "Tags to be applied to reasources created by this module"
  type        = map(string)
  default     = {}
}
variable "dev_mode" {
  description = "Enable to deploy smaller sized instances for testing"
  type        = bool
  default     = false
}
variable "detailed_monitoring" {
  description = "Enable detailed monitoring all instances created"
  type        = bool
  default     = false
}
variable "dns_hostnames" {
  description = "Use IP address or DNS hostname of EIP to create strongDM gateways"
  type        = bool
  default     = true
}
variable "encryption_key" {
  description = "Specify a customer key to use for SSM parameter store encryption."
  type        = string
  default     = null
}
variable "enable_cpu_alarm" {
  description = "CloudWatch alarm: 75% cpu utilization for 10 minutes."
  type        = bool
  default     = false
}

#################
# Sources latest Amazon Linux 2 AMI ID
#################
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

#################
# Locals
#################
locals {
  create_relay   = local.relay_count > 0 ? true : false
  create_gateway = local.gateway_count > 0 ? true : false

  gateway_count = length(var.gateway_subnet_ids)
  relay_count   = length(var.relay_subnet_ids)
  node_count    = local.gateway_count + local.relay_count
}
