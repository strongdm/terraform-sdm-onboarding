# AWS Provider - Uses the region variable and standard AWS authentication methods
provider "aws" {
  region = var.region # Region can be specified in terraform.tfvars
}

terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 12.0.0"
    }
  }
}
