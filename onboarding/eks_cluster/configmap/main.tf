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