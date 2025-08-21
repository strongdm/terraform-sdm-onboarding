# =============================================================================
# NETWORK MODULE VARIABLES
# =============================================================================
# Variable definitions for the VPC networking module. This module creates
# the foundational network infrastructure for StrongDM deployments.
# =============================================================================

variable "name" {
  description = <<-EOT
    Base name for VPC and networking resources.
    Used to create consistent resource names and tags across the network infrastructure.
    
    Resources created:
    - VPC: "[name]-vpc"
    - Subnets: "[name]-vpc-private-[az]", "[name]-vpc-public-[az]"
    - Route tables, NAT gateways, and internet gateway
    
    Example: "terraform-sdm" creates VPC named "terraform-sdm-vpc"
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
    Map of tags to apply to all networking resources.
    These tags are merged with resource-specific tags for comprehensive labeling.
    
    Common tags to include:
    - Environment (production, staging, development)
    - Team or department ownership
    - Cost center for billing allocation
    - Project or application identifier
    
    Example: {
      Environment = "production"
      Team        = "platform"
      Project     = "strongdm-onboarding"
    }
  EOT
  type        = map(string)
  default     = {}
}
