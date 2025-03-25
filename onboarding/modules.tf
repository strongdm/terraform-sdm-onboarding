module "network" {
  count  = var.create_vpc ? 1 : 0
  source = "./network"
  name   = var.name
  tags   = local.tags
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.7.3"

  cluster_name = local.ecs_cluster_name

  create_cloudwatch_log_group = false

  fargate_capacity_providers = { FARGATE = "" }

  tags = local.tags
}

module "sdm_proxy_cluster" {
  count            = var.use_gateways ? 0 : 1
  source           = "./sdm_proxy_cluster"
  name             = var.name
  vpc_id           = local.vpc_id
  ecs_cluster_name = local.ecs_cluster_name

  private_subnet_ids  = local.private_subnet_ids
  public_subnet_ids   = local.public_subnet_ids
  ingress_cidr_blocks = var.ingress_cidr_blocks

  tags = local.tags
}

module "sdm_gateway" {
  count               = var.use_gateways ? 1 : 0
  source              = "./sdm_gateway"
  sdm_node_name       = var.name
  deploy_vpc_id       = local.vpc_id
  gateway_subnet_ids  = local.public_subnet_ids
  gateway_ingress_ips = var.ingress_cidr_blocks
  tags                = local.tags
}

module "windows_server" {
  count            = var.create_rdp ? 1 : 0
  source           = "./windows_server"
  name             = var.name
  security_group   = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)
  subnet_id        = local.private_subnet_ids[0]
  tags             = local.tags
  vpc_id           = local.vpc_id
  proxy_cluster_id = try(module.sdm_proxy_cluster[0].id, "")
}

module "eks" {
  count                    = var.create_eks ? 1 : 0
  source                   = "./eks_cluster"
  name                     = var.name
  subnet_ids               = local.private_subnet_ids
  vpc_id                   = local.vpc_id
  tags                     = local.tags
  proxy_cluster_id         = try(module.sdm_proxy_cluster[0].id, "")
  worker_role_arn          = try(module.sdm_proxy_cluster[0].worker_role_arn, module.sdm_gateway[0].role_arn)
  worker_security_group_id = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)
}

module "mysql" {
  count            = var.create_mysql ? 1 : 0
  source           = "./mysql"
  name             = var.name
  vpc_id           = local.vpc_id
  tags             = local.tags
  security_group   = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)
  subnet_ids       = local.private_subnet_ids
  proxy_cluster_id = try(module.sdm_proxy_cluster[0].id, "")
}

module "http_website" {
  count            = var.create_http_ssh ? 1 : 0
  source           = "./http"
  name             = var.name
  vpc_id           = local.vpc_id
  tags             = local.tags
  security_group   = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)
  subnet_id        = local.private_subnet_ids[0]
  ssh_pubkey       = data.sdm_ssh_ca_pubkey.this_key.public_key
  proxy_cluster_id = try(module.sdm_proxy_cluster[0].id, "")
}
