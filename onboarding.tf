# =============================================================================
# STRONGDM ONBOARDING MODULE
# =============================================================================
# This is the main module configuration for StrongDM AWS onboarding.
# It orchestrates the creation of various AWS resources and StrongDM 
# integrations including EKS clusters, databases, servers, and networking.
#
# Features:
#   - Amazon EKS cluster with StrongDM proxy integration
#   - MySQL RDS database instances with secure access
#   - Windows RDP servers for remote desktop access  
#   - HTTP/SSH resources for web and shell access
#   - VPC networking with security groups and subnets
#   - StrongDM user roles and access policies
#
# Estimated Provisioning Times:
#   - EKS Cluster: ~20 minutes
#   - MySQL Database: ~15 minutes  
#   - RDP Server: ~10 minutes
#   - HTTP/SSH Resources: ~5 minutes
#   - VPC Infrastructure: ~5 minutes
#
# Prerequisites:
#   - StrongDM API keys configured as environment variables
#   - AWS credentials with appropriate permissions
#   - TLS certificate setup for HTTP resources (if enabled)
# =============================================================================

module "strongdm_onboarding" {
  source = "./onboarding"

  # Resource naming prefix - will be added to all resource names for identification
  # Example: "terraform-sdm" creates resources like "terraform-sdm-eks", "terraform-sdm-mysql"
  name = "terraform-sdm"

  # =============================================================================
  # RESOURCE TOGGLES
  # =============================================================================
  # Enable/disable specific resources based on your testing needs.
  # Each resource can be independently controlled via these boolean flags.

  # Amazon EKS Kubernetes cluster with StrongDM integration
  # Creates: EKS cluster, node groups, security groups, IAM roles
  # Estimated time: ~20 minutes
  # create_eks = false

  # MySQL RDS database instances with secure StrongDM access
  # Creates: RDS MySQL instance, subnet groups, security groups
  # Estimated time: ~15 minutes  
  # create_mysql = true

  # Windows Server EC2 instance with RDP access via StrongDM
  # Creates: EC2 Windows instance, security groups, StrongDM RDP resource
  # Estimated time: ~10 minutes
  # create_rdp = false

  # HTTP and SSH resources for web/shell access through StrongDM
  # Creates: EC2 Linux instance, security groups, StrongDM HTTP/SSH resources
  # Estimated time: ~5 minutes
  # create_http_ssh = false

  # =============================================================================
  # NETWORKING CONFIGURATION
  # =============================================================================

  # VPC creation toggle - creates dedicated VPC infrastructure
  # If disabled, uses default VPC (not recommended for production)
  # Creates: VPC, subnets, internet gateway, route tables, NAT gateways
  # Estimated time: ~5 minutes
  # create_vpc = true

  # Optional: Override VPC configuration
  # vpc_id = "vpc-12345678"           # Use existing VPC
  # subnet_ids = ["subnet-abcd1234"]  # Use specific subnets

  # =============================================================================
  # ACCESS CONTROL CONFIGURATION
  # =============================================================================

  # Grant access to existing StrongDM users by email address
  # These users will receive access to all provisioned resources
  # Example: ["admin@company.com", "developer@company.com"] 
  # grant_to_existing_users = []

  # Network access control for StrongDM proxy ingress
  # Default allows global access (0.0.0.0/0) - restrict for production use
  # Example: ["10.0.0.0/8", "192.168.0.0/16"] for private networks
  # ingress_cidr_blocks = ["0.0.0.0/0"]

  # =============================================================================
  # RESOURCE TAGGING
  # =============================================================================

  # Common tags applied to all AWS and StrongDM resources
  # Useful for cost tracking, resource management, and compliance
  # Example: { Environment = "sandbox", Team = "platform", Project = "sdm-onboarding" }
  # tags = {}
}
