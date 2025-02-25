locals {
  ecs_cluster_name   = var.name
  vpc_id             = var.create_vpc ? module.network[0].vpc_id : data.aws_vpc.default[0].id
  public_subnet_ids  = var.create_vpc ? module.network[0].public_subnet_ids : (var.public_subnet_ids != null ? var.public_subnet_ids : data.aws_subnets.subnets[0].ids)
  private_subnet_ids = var.create_vpc ? module.network[0].private_subnet_ids : (var.private_subnet_ids != null ? var.private_subnet_ids : local.public_subnet_ids)
  tags = merge(var.tags, {
    CreatedBy = "strongDM-Onboarding"
    Terraform = "true"
  })
}
