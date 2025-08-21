# =============================================================================
# LOCAL VALUES
# =============================================================================
# This file contains computed local values used throughout the StrongDM 
# onboarding modules. These values handle conditional logic for networking
# and provide consistent resource naming and tagging.
#
# Key Functions:
#   - Network resource selection (VPC vs default VPC)
#   - Subnet assignment logic for public/private placement  
#   - Standardized resource tagging
#   - ECS cluster naming convention
# =============================================================================

locals {
  # ECS cluster naming - uses the base name for consistency
  ecs_cluster_name = var.name

  # VPC selection logic
  # If create_vpc = true: use module-created VPC
  # If create_vpc = false: use default VPC or explicitly provided vpc_id
  vpc_id = var.create_vpc ? module.network[0].vpc_id : data.aws_vpc.default[0].id

  # Public subnet selection logic
  # Priority order: 1) Module-created 2) Explicitly provided 3) Default VPC subnets
  public_subnet_ids = var.create_vpc ? module.network[0].public_subnet_ids : (
    var.public_subnet_ids != null ? var.public_subnet_ids : data.aws_subnets.subnets[0].ids
  )

  # Private subnet selection logic  
  # Priority order: 1) Module-created 2) Explicitly provided 3) Fallback to public subnets
  # Note: When using default VPC, private subnets default to public subnets if not specified
  private_subnet_ids = var.create_vpc ? module.network[0].private_subnet_ids : (
    var.private_subnet_ids != null ? var.private_subnet_ids : local.public_subnet_ids
  )

  # Standardized resource tagging
  # Merges user-provided tags with consistent identifying tags
  tags = merge(var.tags, {
    CreatedBy = "strongDM-Onboarding" # Identifies resources created by this module
    Terraform = "true"                # Marks resources as Terraform-managed
  })
}
