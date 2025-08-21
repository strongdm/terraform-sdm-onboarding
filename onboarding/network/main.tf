# =============================================================================
# NETWORK MODULE - VPC INFRASTRUCTURE
# =============================================================================
# This module creates a complete VPC infrastructure for StrongDM deployments
# including public/private subnets, NAT gateways, and internet connectivity.
#
# Architecture:
#   - VPC with 10.0.0.0/16 CIDR (65,534 IP addresses)
#   - Public subnets for NAT gateways and load balancers  
#   - Private subnets for databases, EKS nodes, and EC2 instances
#   - Multi-AZ deployment for high availability
#   - DNS hostnames and resolution enabled for EKS compatibility
#
# Security Features:
#   - Private subnets have no direct internet access
#   - NAT gateways provide outbound internet for private resources
#   - Proper routing tables for network isolation
# =============================================================================

terraform {
  # Terraform version constraint for network module
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0" 
    }
  }
}

# -----------------------------------------------------------------------------
# AVAILABILITY ZONE DISCOVERY
# -----------------------------------------------------------------------------
# Dynamically discover available AZs in the current region
# Ensures subnets are created in valid, operational zones
data "aws_availability_zones" "available" {
  state = "available"

  # Filter out local zones and wavelength zones for standard deployment
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# -----------------------------------------------------------------------------
# VPC CREATION
# -----------------------------------------------------------------------------
# Creates complete VPC infrastructure using the community VPC module
# Provides high availability across multiple availability zones
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.0"

  # VPC identification and CIDR configuration
  name = "${var.name}-vpc"
  cidr = "10.0.0.0/16" # Provides 65,534 IP addresses for all resources

  # Multi-AZ deployment for high availability
  # Uses all available AZs in the region for maximum resilience
  azs = data.aws_availability_zones.available.zone_ids

  # Private subnet configuration (no direct internet access)
  # Used for: EKS nodes, RDS databases, private EC2 instances
  # Each /24 subnet provides 254 IP addresses
  private_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

  # Public subnet configuration (direct internet access)
  # Used for: NAT gateways, Application Load Balancers, bastion hosts
  # Each /24 subnet provides 254 IP addresses  
  public_subnets = ["10.0.102.0/24", "10.0.103.0/24"]

  # Enable NAT Gateway for private subnet internet access
  # Required for EKS nodes to pull container images and communicate with EKS control plane
  enable_nat_gateway = true

  # Single NAT Gateway configuration (cost-effective for development)
  # For production, consider: single_nat_gateway = false for multi-AZ NAT redundancy
  single_nat_gateway = true

  # Enable DNS features required for EKS and service discovery
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Resource tagging for identification and cost tracking
  # Includes EKS-required tags for subnet discovery
  tags = merge(
    {
      Name                                    = "${var.name}-vpc"
      "kubernetes.io/cluster/${var.name}-eks" = "shared" # EKS cluster association
    },
    var.tags,
  )

  # Additional subnet tags for Kubernetes integration
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1" # For external load balancers
    Type                     = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1" # For internal load balancers
    Type                              = "private"
  }
}
