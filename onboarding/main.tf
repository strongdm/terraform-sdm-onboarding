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

module "eks" {
  source       = "./eks_cluster"
  create_eks   = var.create_eks
  prefix       = var.prefix
  subnet_ids   = local.subnet_ids
  vpc_id       = local.vpc_id
  default_tags = local.default_tags
  tags         = var.tags
  admins_id    = sdm_role.admins.id
}

module "mysql" {
  count          = var.create_mysql ? 1 : 0
  source         = "./mysql"
  create_ssh     = var.create_ssh
  ssh_pubkey     = data.sdm_ssh_ca_pubkey.this_key.public_key
  prefix         = var.prefix
  vpc_id         = local.vpc_id
  tags           = var.tags
  default_tags   = local.default_tags
  security_group = module.sdm.gateway_security_group_id
  subnet_ids     = local.subnet_ids
  admins_id      = sdm_role.admins.id
  read_only_id   = sdm_role.read_only.id
}
