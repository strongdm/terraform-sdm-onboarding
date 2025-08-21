terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0" 
    }
    sdm = {
      source  = "strongdm/sdm"
      version = ">= 15.0.0"
    }
  }
}

# =============================================================================
# AMAZON EKS CLUSTER CREATION
# =============================================================================
# Creates an Amazon EKS cluster with StrongDM integration for secure 
# Kubernetes access. The cluster is configured with proper networking,
# security groups, and IAM permissions for StrongDM proxy connectivity.
#
# Features:
#   - Multi-AZ deployment for high availability
#   - Private subnet placement for enhanced security  
#   - StrongDM proxy integration via access entries
#   - Cluster security group rules for proxy access
#   - Automatic StrongDM resource registration
# =============================================================================

module "eks" {
  source              = "terraform-aws-modules/eks/aws"
  version             = "~> 21.0"
  name                = "${var.name}-eks"
  kubernetes_version  = "1.33"
  subnet_ids          = var.subnet_ids
  vpc_id              = var.vpc_id

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

  security_group_additional_rules = {
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

# =============================================================================
# STRONGDM EKS RESOURCE REGISTRATION
# =============================================================================
# Registers the EKS cluster as a StrongDM resource to enable secure access
# through the StrongDM proxy network. This creates a managed connection that
# allows authorized users to access Kubernetes via kubectl through StrongDM.
#
# Configuration:
#   - Extracts cluster endpoint and region from EKS outputs
#   - Configures certificate authority for TLS verification
#   - Associates with specified StrongDM proxy cluster
#   - Inherits IAM permissions from proxy worker role
# =============================================================================

resource "sdm_resource" "k8s_eks_data_eks" {
  amazon_eks_instance_profile {
    # Resource name in StrongDM - must be unique within organization
    name         = "${var.name}-eks"
    cluster_name = module.eks.cluster_name

    # Associate with StrongDM proxy cluster for connection routing
    proxy_cluster_id = var.proxy_cluster_id

    # EKS cluster TLS certificate authority for secure connections
    # Decoded from base64 format provided by EKS module
    certificate_authority = base64decode(module.eks.cluster_certificate_authority_data)

    # Extract hostname from full EKS endpoint URL
    # Example: https://ABC123.gr7.us-west-2.eks.amazonaws.com → ABC123.gr7.us-west-2.eks.amazonaws.com
    endpoint = split("//", module.eks.cluster_endpoint)[1]

    # Extract AWS region from EKS endpoint for proper API routing
    # Example: ABC123.gr7.us-west-2.eks.amazonaws.com → us-west-2
    region = split(".", module.eks.cluster_endpoint)[2]

    # Resource tags for organization and cost tracking
    # Merges module tags with EKS-specific naming tag
    tags = merge({
      Name = "${var.name}-eks"
    }, var.tags)
  }
}
