module "windows_server" {
  count          = var.create_rdp ? 1 : 0
  source         = "./windows_server"
  default_tags   = local.default_tags
  prefix         = var.prefix
  security_group = module.sdm.gateway_security_group_id
  subnet_ids     = local.subnet_ids[0]
  tags           = var.tags
  vpc_id         = local.vpc_id
  admins_id      = sdm_role.admins.id
}

module "eks_cluster" {
  count        = var.create_eks ? 1 : 0
  source       = "./eks_cluster"
  prefix       = var.prefix
  subnet_ids   = local.subnet_ids
  vpc_id       = local.vpc_id
  default_tags = local.default_tags
  tags         = var.tags
  admins_id    = sdm_role.admins.id
}
