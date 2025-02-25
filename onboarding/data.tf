# ---------------------------------------------------------------------------- #
# These data-sources gather the necessary VPC information if create VPC is not specified
# ---------------------------------------------------------------------------- #
data "aws_vpc" "default" {
  count = var.create_vpc ? 0 : 1

  id = var.vpc_id

  default = var.vpc_id == null
}

data "aws_subnets" "subnets" {
  count = var.create_vpc ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# ---------------------------------------------------------------------------- #
# Grab the strongDM CA public key for the authenticated organization
# ---------------------------------------------------------------------------- #
data "sdm_ssh_ca_pubkey" "this_key" {}

data "sdm_account" "existing_users" {
  count = length(var.grant_to_existing_users)
  type  = "user"
  email = var.grant_to_existing_users[count.index]
}
