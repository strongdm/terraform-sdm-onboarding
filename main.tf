# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
# This file defines the core Terraform configuration including required 
# providers and version constraints for the StrongDM AWS onboarding module.
#
# Dependencies:
#   - AWS Provider: For provisioning AWS infrastructure resources
#   - StrongDM Provider: For managing StrongDM resources and integrations
#
# Usage:
#   This configuration sets the foundation for the entire StrongDM 
#   onboarding infrastructure deployment.
# =============================================================================

terraform {
  # Minimum Terraform version required for this configuration
  # Uses features available in Terraform 1.0.0+ including:
  # - Stable feature set and consistent behavior
  # - Enhanced variable validation and lifecycle management
  # - Improved provider dependency resolution
  required_version = ">= 1.0.0"

  required_providers {
    # AWS Provider - manages AWS infrastructure resources
    # Used for: VPC, EKS, RDS, EC2, Security Groups, etc.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0" 
    }

    # StrongDM Provider - manages StrongDM resources and access policies  
    # Used for: proxy clusters, resource registration, user access, roles
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 15.0.0"
    }
  }
}
