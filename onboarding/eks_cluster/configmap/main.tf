terraform {
  required_version = ">= 0.14.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.35.1"
    }
  }
}

# New ConfigMap option
resource "kubernetes_config_map" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = <<YAML
- rolearn: ${var.role_arn}
  username: kubectl-access-user
  groups:
    - system:masters
YAML
  }
}
