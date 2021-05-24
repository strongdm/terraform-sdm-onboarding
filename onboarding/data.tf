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

# ---------------------------------------------------------------------------- #
# Grab the strongDM CA public key for the authenticated organization
# ---------------------------------------------------------------------------- #
data "sdm_ssh_ca_pubkey" "this_key" {}
