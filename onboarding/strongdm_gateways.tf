module "sdm" {
  source        = "./terraform_aws_strongdm_gateways"
  enable_module = var.create_strongdm_gateways

  sdm_node_name = "${var.prefix}-gateway"

  deploy_vpc_id = local.vpc_id

  gateway_subnet_ids = [
    local.subnet_ids[0],
    local.subnet_ids[1],
  ]
  tags = merge(local.default_tags, var.tags)
}

