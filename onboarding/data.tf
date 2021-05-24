# ---------------------------------------------------------------------------- #
# These data-sources gather the necessary VPC information if create VPC is not specified
# ---------------------------------------------------------------------------- #
data "aws_vpc" "default" {
  count   = var.create_vpc ? 0 : 1
  default = true
}

data "aws_subnet_ids" "subnets" {
  count  = var.create_vpc ? 0 : 1
  vpc_id = data.aws_vpc.default[0].id
}

locals {
  vpc_id         = var.create_vpc ? module.vpc.vpc_id : data.aws_vpc.default[0].id
  vpc_cidr_block = var.create_vpc ? module.vpc.vpc_cidr_block : data.aws_vpc.default[0].cidr_block
  subnet_ids     = var.create_vpc ? module.vpc.public_subnets : sort(data.aws_subnet_ids.subnets[0].ids)
  default_tags   = { CreatedBy = "strongDM-Onboarding" }
}

# ---------------------------------------------------------------------------- #
# Grab the strongDM CA public key for the authenticated organization
# ---------------------------------------------------------------------------- #
data "sdm_ssh_ca_pubkey" "this_key" {}
