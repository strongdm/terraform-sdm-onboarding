# ---------------------------------------------------------------------------- #
# Create EKS cluster
# ---------------------------------------------------------------------------- #
locals {
  rolearn = aws_iam_role.eks_role.arn
}

data "aws_eks_cluster" "eks_data" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "eks_data" {
  name = module.eks_cluster.cluster_id
}


module "eks_cluster" {
  source = "terraform-aws-modules/eks/aws"
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/12.2.0

  cluster_name    = "${var.prefix}-eks"
  cluster_version = "1.17"
  subnets         = var.subnet_ids
  vpc_id          = var.vpc_id

  map_roles = [{
    # This role will be added to the aws_auth file and strongDM will use these credentials. 
    rolearn  = local.rolearn
    username = split("/", local.rolearn)[length(split("/", local.rolearn)) - 1]
    groups   = ["system:masters"]
  }]

  worker_groups = [
    {
      instance_type = "t3.small"
      asg_max_size  = 1
    }
  ]
  providers = {
    kubernetes = kubernetes.eks
  }
  tags = merge({ Name = "${var.prefix}-eks" }, var.default_tags, var.tags)
}

# ---------------------------------------------------------------------------- #
# Grant control of EKS to Terraform to add aws_auth file
# ---------------------------------------------------------------------------- #

provider "kubernetes" {
  alias = "eks"

  host                   = data.aws_eks_cluster.eks_data.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_data.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks_data.token
}

# ---------------------------------------------------------------------------- #
# Create IAM user for strongDM to access EKS cluster
# ---------------------------------------------------------------------------- #

resource "aws_iam_user" "eks_user" {
  # This user is not granted any permissions.
  name = "${var.prefix}-eks-user-strongdm"
  path = "/terraform/"
  tags = merge({
    Name = "${var.prefix}-eks"
  }, var.default_tags, var.tags)
}

resource "aws_iam_access_key" "eks_user" {
  # An access key is created for the IAM user generate an iam-authenticator token.
  user = aws_iam_user.eks_user.name
}

resource "aws_iam_role" "eks_role" {
  # This role is listed inside the EKS cluster and is where strongDM will inherit permissions.
  name = "${var.prefix}-eks-user-strongdm"

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
          "${aws_iam_user.eks_user.arn}"
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
  amazon_eks {
    name         = "${var.prefix}-eks"
    cluster_name = data.aws_eks_cluster.eks_data.name

    endpoint = split("//", data.aws_eks_cluster.eks_data.endpoint)[1]
    region   = split(".", data.aws_eks_cluster.eks_data.endpoint)[2]

    certificate_authority = base64decode(data.aws_eks_cluster.eks_data.certificate_authority.0.data)

    # IAM Credentials are used to access the cluster via iam-authenticator
    access_key        = aws_iam_access_key.eks_user.id
    secret_access_key = aws_iam_access_key.eks_user.secret

    # When specified strongDM will inherit permissions from this role 
    role_arn = aws_iam_role.eks_role.arn
    tags = merge({
      Name = "${var.prefix}-eks"
    }, var.default_tags, var.tags)
  }
}

resource "sdm_role_grant" "admin_grant_eks" {
  role_id     = var.admins_id
  resource_id = sdm_resource.k8s_eks_data_eks.id
}
