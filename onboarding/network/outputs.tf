# =============================================================================
# NETWORK MODULE OUTPUTS
# =============================================================================
# Output values from the VPC networking module for use by other modules.
# These outputs provide essential networking information for resource deployment
# across the StrongDM infrastructure.
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC created for StrongDM infrastructure deployment"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC (10.0.0.0/16) for network planning and security group rules"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = <<-EOT
    List of private subnet IDs for secure resource deployment.
    Used by: EKS nodes, RDS databases, EC2 instances, StrongDM proxies.
    These subnets have no direct internet access and route through NAT gateways.
  EOT
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = <<-EOT
    List of public subnet IDs for internet-facing resources.
    Used by: NAT gateways, Application Load Balancers, bastion hosts (if needed).
    These subnets have direct internet gateway access.
  EOT
  value       = module.vpc.public_subnets
}
