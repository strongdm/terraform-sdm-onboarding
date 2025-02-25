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
  source           = "./sdm_proxy_cluster"
  name             = var.name
  vpc_id           = local.vpc_id
  ecs_cluster_name = local.ecs_cluster_name

  private_subnet_ids  = local.private_subnet_ids
  public_subnet_ids   = local.public_subnet_ids
  ingress_cidr_blocks = var.ingress_cidr_blocks

  tags = local.tags
}

module "windows_server" {
  count            = var.create_rdp ? 1 : 0
  source           = "./windows_server"
  name             = var.name
  security_group   = module.sdm_proxy_cluster.worker_security_group_id
  subnet_id        = local.private_subnet_ids[0]
  tags             = local.tags
  vpc_id           = local.vpc_id
  proxy_cluster_id = module.sdm_proxy_cluster.id
}

module "eks" {
  source           = "./eks_cluster"
  create_eks       = var.create_eks
  name             = var.name
  subnet_ids       = local.private_subnet_ids
  vpc_id           = local.vpc_id
  tags             = local.tags
  proxy_cluster_id = module.sdm_proxy_cluster.id
}

module "mysql" {
  count            = var.create_mysql ? 1 : 0
  source           = "./mysql"
  name             = var.name
  vpc_id           = local.vpc_id
  tags             = local.tags
  security_group   = module.sdm_proxy_cluster.worker_security_group_id
  subnet_ids       = local.private_subnet_ids
  proxy_cluster_id = module.sdm_proxy_cluster.id
}

module "http_website" {
  count            = var.create_http ? 1 : 0
  source           = "./http"
  create_ssh       = var.create_ssh
  name             = var.name
  vpc_id           = local.vpc_id
  tags             = local.tags
  security_group   = module.sdm_proxy_cluster.worker_security_group_id
  subnet_ids       = local.private_subnet_ids
  ssh_pubkey       = data.sdm_ssh_ca_pubkey.this_key.public_key
  proxy_cluster_id = module.sdm_proxy_cluster.id
}
