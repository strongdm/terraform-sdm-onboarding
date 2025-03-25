terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "${var.name}-vpc"
  cidr = "10.0.0.0/16"

  azs = data.aws_availability_zones.available.names

  private_subnets = ["10.0.100.0/24", "10.0.101.0/24"]
  public_subnets  = ["10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = merge(
    { Name = "${var.name}-vpc" },
    var.tags,
  )
}
