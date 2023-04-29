terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = ">= 3.0.0"
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 1.0.15"
    }
  }
}

# ---------------------------------------------------------------------------- #
# Create EKS cluster
# ---------------------------------------------------------------------------- #

locals {
  rolearn = var.create_eks ? aws_iam_role.eks_role[0].arn : "rolearn/rolearn"
}

module "eks" {
  source     = "terraform-aws-modules/eks/aws"
  create = var.create_eks
  cluster_name    = "${var.prefix}-eks"
  cluster_version = "1.21"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  tags = merge({ Name = "${var.prefix}-eks" }, var.default_tags, var.tags)
}

# ---------------------------------------------------------------------------- #
# Grant control of EKS to Terraform to add aws_auth file
# ---------------------------------------------------------------------------- #

data "aws_eks_cluster" "eks_data" {
  count = var.create_eks ? 1 : 0
  name  = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "eks_data" {
  count = var.create_eks ? 1 : 0
  name  = module.eks.cluster_name
}

provider "kubernetes" {
  # alias = "eks"
  host                   = var.create_eks ? data.aws_eks_cluster.eks_data[0].endpoint : null
  cluster_ca_certificate = var.create_eks ? base64decode(data.aws_eks_cluster.eks_data[0].certificate_authority.0.data) : null
  token                  = var.create_eks ? data.aws_eks_cluster_auth.eks_data[0].token : null
} 

# ---------------------------------------------------------------------------- #
# Create IAM user for strongDM to access EKS cluster
# ---------------------------------------------------------------------------- #

resource "aws_iam_user" "eks_user" {
  # This user is not granted any permissions.
  count = var.create_eks ? 1 : 0
  name  = "${var.prefix}-eks-user-strongdm"
  path  = "/terraform/"
  tags = merge({
    Name = "${var.prefix}-eks"  
  }, var.default_tags, var.tags)
}

resource "aws_iam_access_key" "eks_user" {
  # An access key is created for the IAM user generate an iam-authenticator token.
  count = var.create_eks ? 1 : 0
  user  = aws_iam_user.eks_user[0].name
}

resource "aws_iam_role" "eks_role" {
  # This role is listed inside the EKS cluster and is where strongDM will inherit permissions.
  count = var.create_eks ? 1 : 0
  name  = "${var.prefix}-eks-user-strongdm"

  # This policy restricts this role so it can only be used by the IAM user created above.
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeEKS",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_user.eks_user[0].arn}"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ---------------------------------------------------------------------------- #
# Register the EKS cluster with strongDM
# ---------------------------------------------------------------------------- #

resource "sdm_resource" "k8s_eks_data_eks" {
  count = var.create_eks ? 1 : 0
  amazon_eks {
    name         = "${var.prefix}-eks"
    cluster_name = data.aws_eks_cluster.eks_data[0].name

    endpoint = split("//", data.aws_eks_cluster.eks_data[0].endpoint)[1]
    region   = split(".", data.aws_eks_cluster.eks_data[0].endpoint)[2]

    certificate_authority = base64decode(data.aws_eks_cluster.eks_data[0].certificate_authority.0.data)

    # IAM Credentials are used to access the cluster via iam-authenticator
    access_key        = aws_iam_access_key.eks_user[0].id
    secret_access_key = aws_iam_access_key.eks_user[0].secret

    # When specified strongDM will inherit permissions from this role
    role_arn = aws_iam_role.eks_role[0].arn
    tags = merge({
      Name = "${var.prefix}-eks"
    }, var.default_tags, var.tags)
  }
}

module "configmap" {
  count       = var.create_eks ? 1 : 0
  source = "./configmap"
  role_arn = local.rolearn
}
