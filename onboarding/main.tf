terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = ">= 3.0.0"
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 4.0.0"
    }
  }
}

module "network" {
  count        = var.create_vpc ? 1 : 0
  source       = "./network"
  prefix       = var.prefix
  default_tags = local.default_tags
  tags         = var.tags
}

module "sdm" {
  count         = var.create_strongdm_gateways ? 1 : 0
  source        = "./sdm_gateway"
  sdm_node_name = "${var.prefix}-gateway"
  deploy_vpc_id = local.vpc_id
  gateway_subnet_ids = [
    local.subnet_ids[0],
    local.subnet_ids[1]
  ]
  tags = merge(local.default_tags, var.tags)
}


module "windows_server" {
  count          = var.create_rdp ? 1 : 0
  source         = "./windows_server"
  default_tags   = local.default_tags
  prefix         = var.prefix
  security_group = var.create_strongdm_gateways ? module.sdm[0].gateway_security_group_id : data.aws_security_group.default_security_group[0].id
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
  security_group = var.create_strongdm_gateways ? module.sdm[0].gateway_security_group_id : data.aws_security_group.default_security_group[0].id
  subnet_ids     = local.subnet_ids
  admins_id      = sdm_role.admins.id
  read_only_id   = sdm_role.read_only.id
}

module "http_website" {
  count          = var.create_http ? 1 : 0
  source         = "./http"
  create_ssh     = var.create_ssh
  prefix         = var.prefix
  vpc_id         = local.vpc_id
  tags           = var.tags
  default_tags   = local.default_tags
  security_group = var.create_strongdm_gateways ? module.sdm[0].gateway_security_group_id : data.aws_security_group.default_security_group[0].id
  subnet_ids     = local.subnet_ids
  ssh_pubkey     = data.sdm_ssh_ca_pubkey.this_key.public_key
  admins_id      = sdm_role.admins.id
  read_only_id   = sdm_role.read_only.id
}

resource "sdm_policy" "permit_everything" {
  name        = "permit-everything"
  description = "Permits everything"

  policy = <<EOP
permit(principal, action, resource);
EOP
}
