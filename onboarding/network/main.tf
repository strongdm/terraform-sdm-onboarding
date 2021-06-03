terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = ">= 3.0.0"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
    data.aws_availability_zones.available.names[2],
  ]

  private_subnets = ["10.0.100.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = merge(
    { Name = "${var.prefix}-vpc" },
    var.default_tags,
    var.tags,
  )
}
