# =============================================================================
# EKS CLUSTER MODULE VARIABLES
# =============================================================================
# Variable definitions for the Amazon EKS cluster module with StrongDM 
# integration. This module creates an EKS cluster and registers it with
# StrongDM for secure Kubernetes access.
#
# Key Components:
#   - Amazon EKS cluster with configurable Kubernetes version
#   - StrongDM resource registration for cluster access
#   - Security group integration with StrongDM proxy workers
#   - IAM role configuration for StrongDM authentication
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE IDENTIFICATION
# -----------------------------------------------------------------------------

variable "name" {
  description = <<-EOT
    Base name for EKS cluster and related resources. 
    Applied to resource names, titles, and tags for consistent identification.
    
    Example: "terraform-sdm" creates cluster "terraform-sdm-eks"
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
    Map of tags to apply to all resources created by this module.
    Used for cost tracking, resource management, and compliance.
    
    Example: {
      Environment = "production"
      Team        = "platform"
      Project     = "strongdm-onboarding"
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
    StrongDM proxy cluster ID to assign the EKS resource to.
    This determines which proxy cluster will handle connections to the EKS cluster.
    
    Obtained from the StrongDM proxy cluster module output.
  EOT
  type        = string
}

variable "worker_role_arn" {
  description = <<-EOT
    IAM Role ARN of StrongDM proxy workers.
    This role will receive permissions to authenticate and connect to the EKS cluster.
    
    The role is granted access through EKS access entries for cluster authentication.
  EOT
  type        = string
}

variable "worker_security_group_id" {
  description = <<-EOT
    Security group ID assigned to StrongDM proxy workers.
    Used to configure network access rules for proxy-to-EKS communication.
    
    This security group will be granted access to the EKS cluster API endpoint.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# NETWORKING CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = <<-EOT
    ID of the VPC where the EKS cluster will be deployed.
    The VPC must have appropriate DNS settings and internet access for EKS operation.
    
    Requirements:
    - enableDnsHostnames: true
    - enableDnsSupport: true
    - Internet gateway for public access (if needed)
  EOT
  type        = string
}

variable "subnet_ids" {
  description = <<-EOT
    List of subnet IDs where EKS cluster and node groups will be deployed.
    Should include subnets from multiple Availability Zones for high availability.
    
    Requirements:
    - Minimum 2 subnets in different AZs
    - Subnets must have adequate IP address space
    - Private subnets recommended for node groups
    - Public subnets required if using public load balancers
    
    Example: ["subnet-12345678", "subnet-87654321"]
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided for EKS high availability."
  }
}
