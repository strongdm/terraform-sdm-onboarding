terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 4.0.0"
    }
  }
}

# ---------------------------------------------------------------------------- #
# Create EKS cluster
# ---------------------------------------------------------------------------- #

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.33.1"
  cluster_name    = "${var.name}-eks"
  cluster_version = "1.32"
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id

  tags = merge({ Name = "${var.name}-eks" }, var.tags)

  access_entries = {
    strongdm = {
      kubernetes_groups = []
      principal_arn     = var.worker_role_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  cluster_security_group_additional_rules = {
    strongdm = {
      description              = "Allow traffic from proxy workers to API endpoint"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = var.worker_security_group_id
    }
  }
}

# ---------------------------------------------------------------------------- #
# Register the EKS cluster with strongDM
# ---------------------------------------------------------------------------- #

resource "sdm_resource" "k8s_eks_data_eks" {
  amazon_eks_instance_profile {
    name         = "${var.name}-eks"
    cluster_name = module.eks.cluster_name

    proxy_cluster_id = var.proxy_cluster_id

    certificate_authority = base64decode(module.eks.cluster_certificate_authority_data)

    endpoint = split("//", module.eks.cluster_endpoint)[1]
    region   = split(".", module.eks.cluster_endpoint)[2]

    # When specified strongDM will inherit permissions from this role
    tags = merge({
      Name = "${var.name}-eks"
    }, var.tags)
  }
}
