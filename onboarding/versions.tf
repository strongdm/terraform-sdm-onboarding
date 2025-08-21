# =============================================================================
# TERRAFORM AND PROVIDER CONFIGURATION
# =============================================================================
# This file defines the Terraform version constraints and provider 
# configurations for the StrongDM onboarding module.
#
# Provider Configuration:
#   - AWS: Configured with region variable and standard authentication
#   - StrongDM: Uses API keys from environment variables
#
# Authentication Requirements:
#   AWS: AWS_PROFILE, AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY, or IAM roles
#   StrongDM: SDM_API_ACCESS_KEY and SDM_API_SECRET_KEY environment variables
# =============================================================================

# AWS Provider configuration
# Uses standard AWS authentication methods in order of precedence:
#   1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)  
#   2. AWS profile (AWS_PROFILE or default)
#   3. IAM roles (if running on EC2/ECS/Lambda)
#   4. AWS credentials file (~/.aws/credentials)
provider "aws" {
  region = var.region # Region can be overridden via terraform.tfvars or -var flag
}

terraform {
  # Minimum Terraform version - uses modern features like:
  # - Stable feature set and consistent behavior (v1.0+)
  # - Enhanced variable validation and lifecycle management
  # - Improved provider dependency resolution
  # - Full compatibility with EKS module v21 and AWS provider v6
  required_version = ">= 1.0.0"

  required_providers {
    # AWS Provider for infrastructure provisioning
    # Manages VPC, EKS, RDS, EC2, security groups, and IAM resources
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0" 
    }

    # StrongDM Provider for access management
    # Manages proxy clusters, resource registration, user roles, and access policies
    # Uses API keys from SDM_API_ACCESS_KEY and SDM_API_SECRET_KEY environment variables
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 15.0.0"
    }
  }
}
