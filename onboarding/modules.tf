# =============================================================================
# MODULE DECLARATIONS
# =============================================================================
# This file contains all module declarations for the StrongDM onboarding
# infrastructure. Modules are conditionally created based on feature flags
# to allow flexible deployment scenarios.
#
# Module Dependencies:
#   network → (all other modules depend on network outputs)
#   ecs_cluster → sdm_proxy_cluster
#   sdm_proxy_cluster/sdm_gateway → (all resource modules depend on proxy)
#
# Security Note:
#   All modules use try() functions to gracefully handle optional dependencies
#   between proxy clusters and gateways for maximum deployment flexibility.
# =============================================================================

# -----------------------------------------------------------------------------
# NETWORKING MODULE
# -----------------------------------------------------------------------------
# Creates VPC infrastructure including subnets, route tables, and gateways.
# Conditionally deployed based on create_vpc variable.
module "network" {
  count  = var.create_vpc ? 1 : 0
  source = "./network"

  name = var.name
  tags = local.tags
}

# -----------------------------------------------------------------------------
# ECS CLUSTER MODULE  
# -----------------------------------------------------------------------------
# Creates AWS ECS cluster for hosting StrongDM proxy containers.
# Always deployed as it's required for proxy cluster functionality.
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.7.3"

  cluster_name = local.ecs_cluster_name

  # Disable default CloudWatch log group to avoid conflicts
  create_cloudwatch_log_group = false

  # Enable Fargate capacity provider for serverless container execution
  fargate_capacity_providers = { FARGATE = "" }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# STRONGDM PROXY CLUSTER MODULE
# -----------------------------------------------------------------------------
# Creates StrongDM proxy cluster using ECS Fargate for scalable proxy deployment.
# Mutually exclusive with sdm_gateway - only one proxy type is active.
module "sdm_proxy_cluster" {
  count  = var.use_gateways ? 0 : 1
  source = "./sdm_proxy_cluster"

  name             = var.name
  vpc_id           = local.vpc_id
  ecs_cluster_name = local.ecs_cluster_name

  # Network configuration for proxy placement and external access
  private_subnet_ids  = local.private_subnet_ids
  public_subnet_ids   = local.public_subnet_ids
  ingress_cidr_blocks = var.ingress_cidr_blocks

  tags = local.tags
}

# -----------------------------------------------------------------------------
# STRONGDM GATEWAY MODULE (LEGACY)
# -----------------------------------------------------------------------------
# Creates StrongDM gateway using EC2 instances (legacy deployment method).
# Mutually exclusive with sdm_proxy_cluster - only one proxy type is active.
module "sdm_gateway" {
  count  = var.use_gateways ? 1 : 0
  source = "./sdm_gateway"

  sdm_node_name       = var.name
  deploy_vpc_id       = local.vpc_id
  gateway_subnet_ids  = local.public_subnet_ids
  gateway_ingress_ips = var.ingress_cidr_blocks

  tags = local.tags
}

# -----------------------------------------------------------------------------
# WINDOWS RDP SERVER MODULE
# -----------------------------------------------------------------------------
# Creates Windows Server EC2 instance with RDP access through StrongDM.
# Conditionally deployed based on create_rdp variable.
module "windows_server" {
  count  = var.create_rdp ? 1 : 0
  source = "./windows_server"

  name      = var.name
  vpc_id    = local.vpc_id
  subnet_id = local.private_subnet_ids[0]

  # Security group from active proxy type (cluster or gateway)
  security_group   = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)
  proxy_cluster_id = try(module.sdm_proxy_cluster[0].id, "")

  tags = local.tags
}

# -----------------------------------------------------------------------------
# AMAZON EKS CLUSTER MODULE
# -----------------------------------------------------------------------------
# Creates Amazon EKS Kubernetes cluster with StrongDM integration.
# Conditionally deployed based on create_eks variable.
module "eks" {
  count  = var.create_eks ? 1 : 0
  source = "./eks_cluster"

  name       = var.name
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  # StrongDM integration parameters from active proxy type
  proxy_cluster_id         = try(module.sdm_proxy_cluster[0].id, "")
  worker_role_arn          = try(module.sdm_proxy_cluster[0].worker_role_arn, module.sdm_gateway[0].role_arn)
  worker_security_group_id = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)

  tags = local.tags
}

# -----------------------------------------------------------------------------
# MYSQL DATABASE MODULE
# -----------------------------------------------------------------------------
# Creates MySQL RDS instance with secure StrongDM access.
# Conditionally deployed based on create_mysql variable.
module "mysql" {
  count  = var.create_mysql ? 1 : 0
  source = "./mysql"

  name       = var.name
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  # Security group from active proxy type for database access
  security_group   = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)
  proxy_cluster_id = try(module.sdm_proxy_cluster[0].id, "")

  tags = local.tags
}

# -----------------------------------------------------------------------------
# HTTP/SSH RESOURCES MODULE
# -----------------------------------------------------------------------------
# Creates Linux server with HTTP and SSH access through StrongDM.
# Conditionally deployed based on create_http_ssh variable.
module "http_website" {
  count  = var.create_http_ssh ? 1 : 0
  source = "./http"

  name      = var.name
  vpc_id    = local.vpc_id
  subnet_id = local.private_subnet_ids[0]

  # StrongDM SSH CA public key for SSH certificate authentication
  ssh_pubkey = data.sdm_ssh_ca_pubkey.this_key.public_key

  # Security group and proxy configuration from active proxy type
  security_group   = try(module.sdm_proxy_cluster[0].worker_security_group_id, module.sdm_gateway[0].gateway_security_group_id)
  proxy_cluster_id = try(module.sdm_proxy_cluster[0].id, "")

  tags = local.tags
}
