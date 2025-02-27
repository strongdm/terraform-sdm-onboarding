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
    values = [data.aws_vpc.default[0].id]
  }

  dynamic "filter" {
    for_each = var.subnet_ids != null ? [true] : []

    content {
      name   = "subnet-id"
      values = var.subnet_ids
    }
  }
}

data "aws_security_group" "default_security_group" {
  count  = var.create_vpc ? 0 : 1
  vpc_id = var.create_vpc ? module.network[0].vpc_id : data.aws_vpc.default[0].id

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# ---------------------------------------------------------------------------- #
# Grab the strongDM CA public key for the authenticated organization
# ---------------------------------------------------------------------------- #
data "sdm_ssh_ca_pubkey" "this_key" {}
