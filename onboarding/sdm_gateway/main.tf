# =============================================================================
# STRONGDM GATEWAY MODULE (LEGACY)
# =============================================================================
# This module creates legacy StrongDM gateways using EC2 instances for
# secure access to infrastructure resources. This is the traditional
# deployment method before proxy clusters were introduced.
#
# Features:
#   - EC2-based StrongDM gateway deployment
#   - Auto Scaling Group for high availability
#   - Elastic IP addresses for consistent connectivity
#   - Secure token storage in AWS Systems Manager Parameter Store
#   - CloudWatch monitoring and logging integration
#
# DEPRECATION NOTICE:
#   This legacy gateway approach is being phased out in favor of modern
#   proxy clusters (ECS Fargate-based). New deployments should use proxy
#   clusters for better scalability, cost efficiency, and operational simplicity.
#
# Migration Path:
#   Existing gateway deployments can be migrated to proxy clusters.
#   Contact StrongDM support for migration assistance and planning.
# =============================================================================

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

# -----------------------------------------------------------------------------
# STRONGDM GATEWAY NODE REGISTRATION
# -----------------------------------------------------------------------------
# Creates StrongDM gateway nodes in the StrongDM control plane
# Each gateway receives a unique authentication token for secure communication

resource "sdm_node" "gateway" {
  count = local.gateway_count

  gateway {
    # Gateway identification and naming
    name = "${var.sdm_node_name}-gateway-${count.index}"

    # Network configuration for client connections
    # Uses either DNS hostname or IP address based on configuration
    listen_address = "${var.dns_hostnames ? aws_eip.gateway[count.index].public_dns : aws_eip.gateway[count.index].public_ip}:${var.gateway_listen_port}"

    # Local binding configuration for the gateway process
    bind_address = "0.0.0.0:${var.gateway_listen_port}" # Listen on all interfaces
  }
}

# -----------------------------------------------------------------------------
# GATEWAY TOKEN STORAGE
# -----------------------------------------------------------------------------
# Stores StrongDM gateway authentication tokens securely in AWS SSM Parameter Store
# Tokens are encrypted using KMS and accessed by EC2 instances during gateway startup

resource "aws_ssm_parameter" "gateway" {
  count = local.gateway_count

  # Parameter configuration
  type  = "SecureString"                                 # Encrypted parameter type
  value = sdm_node.gateway[count.index].gateway[0].token # StrongDM gateway auth token
  name  = "/strongdm/gateway/${sdm_node.gateway[count.index].gateway[0].name}/token"

  # KMS encryption key for parameter encryption
  key_id = var.encryption_key

  # Resource tagging for organization and cost tracking
  tags = merge({
    "Name" = sdm_node.gateway[count.index].gateway[0].name,
    "Type" = "strongdm-gateway-token"
  }, var.tags)

  # Lifecycle management for token rotation
  lifecycle {
    create_before_destroy = true # Ensure new token exists before destroying old one
  }
}

# =============================================================================
# GATEWAY EC2 INFRASTRUCTURE
# =============================================================================
# Creates the underlying AWS infrastructure for StrongDM gateway deployment
# including EC2 instances, Elastic IP addresses, and network interfaces

# -----------------------------------------------------------------------------
# ELASTIC IP ADDRESSES
# -----------------------------------------------------------------------------
# Creates static public IP addresses for gateway instances
# Provides consistent connectivity endpoints for StrongDM clients

resource "aws_eip" "gateway" {
  count = local.gateway_count

  # Associate with network interface for gateway instance
  network_interface = aws_network_interface.gateway[count.index].id
  domain            = "vpc" # VPC-specific EIP

  tags = merge({
    Name = "${var.sdm_node_name}-gateway-eip-${count.index}",
    Type = "strongdm-gateway-eip"
  }, var.tags)

  # Ensure network interface exists before creating EIP
  depends_on = [aws_network_interface.gateway]
}

# -----------------------------------------------------------------------------
# NETWORK INTERFACES
# -----------------------------------------------------------------------------
# Creates dedicated network interfaces for gateway instances
# Allows for consistent IP assignment and security group management

resource "aws_network_interface" "gateway" {
  count = local.gateway_count

  subnet_id       = var.gateway_subnet_ids[count.index]
  security_groups = [aws_security_group.this["gateway"].id]

  # Enable source/destination checking (default, but explicit for security)
  source_dest_check = true

  tags = merge({
    "Name" = "${var.sdm_node_name}-gateway-nic-${count.index}",
    "Type" = "strongdm-gateway-interface"
  }, var.tags)
}

# -----------------------------------------------------------------------------
# GATEWAY EC2 INSTANCES
# -----------------------------------------------------------------------------
# Creates EC2 instances to run the StrongDM gateway software
# Configured with user data script for automatic gateway installation and startup

resource "aws_instance" "gateway" {
  count = local.gateway_count

  # Instance configuration
  ami           = data.aws_ami.amazon_linux_2.image_id
  instance_type = var.dev_mode ? "t3.micro" : "t3.medium" # Size based on environment

  # StrongDM gateway installation and configuration
  # Template script installs StrongDM relay software and configures authentication
  user_data = templatefile("${path.module}/templates/relay_install/relay_install.tftpl", {
    SDM_TOKEN = aws_ssm_parameter.gateway[count.index].value
  })

  # SSH access configuration (for troubleshooting if needed)
  key_name = var.ssh_key

  # CloudWatch detailed monitoring for performance analysis
  monitoring = var.detailed_monitoring

  # Instance metadata service configuration (IMDSv1 for compatibility)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # Allow both IMDSv1 and IMDSv2 for gateway compatibility
    http_put_response_hop_limit = 2
  }

  # CPU credit configuration for burstable performance instances
  credit_specification {
    # Unlimited CPU credits prevent throttling during high load
    # Critical for gateway performance and connection stability
    cpu_credits = "unlimited"
  }

  # Network interface attachment
  dynamic "network_interface" {
    for_each = count.index < local.gateway_count ? [1] : []
    content {
      network_interface_id = aws_network_interface.gateway[count.index].id
      device_index         = 0 # Primary network interface
    }
  }

  # Lifecycle management for operational stability
  lifecycle {
    # Prevent instance replacement when AMI updates are available
    # Manual updates recommended for gateway stability
    ignore_changes = [ami]

    # Prevent race conditions during EIP association
    # https://github.com/terraform-providers/terraform-provider-aws/issues/2689
    # create_before_destroy = true
  }

  tags = merge({ "Name" = sdm_node.gateway[count.index].gateway[0].name }, var.tags, )
}

#### RELAY

#################
# Create strongDM gateway and store token
#################
resource "sdm_node" "relay" {
  count = local.relay_count

  relay {
    name = "${var.sdm_node_name}-relay-${count.index}"
  }
}
resource "aws_ssm_parameter" "relay" {
  count = local.relay_count

  type  = "SecureString"
  value = sdm_node.relay[count.index].relay[0].token
  name  = "/strongdm/relay/${sdm_node.relay[count.index].relay[0].name}/token"

  key_id = var.encryption_key

  tags = merge({ "Name" = sdm_node.relay[count.index].relay[0].name }, var.tags, )

  depends_on = [aws_ssm_parameter.gateway]

  lifecycle {
    create_before_destroy = true
  }
}
#################
# Instance configuration
#################
resource "aws_instance" "relay" {
  count = local.relay_count

  ami           = data.aws_ami.amazon_linux_2.image_id
  instance_type = var.dev_mode ? "t3.micro" : "t3.medium"
  user_data     = templatefile("${path.module}/templates/relay_install/relay_install.tftpl", { SDM_TOKEN = aws_ssm_parameter.relay[count.index].value })

  key_name   = var.ssh_key
  monitoring = var.detailed_monitoring

  credit_specification {
    # Prevents CPU throttling and potential performance issues with Gateway
    cpu_credits = "unlimited"
  }

  # Relay Attributes
  subnet_id              = var.relay_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.this["relay"].id]

  lifecycle {

    # Prevents Instance from respawning when Amazon Linux 2 is updated
    ignore_changes = [ami]

    # Used to prevent EIP from failing to associate
    # https://github.com/terraform-providers/terraform-provider-aws/issues/2689
    create_before_destroy = true
  }

  tags = merge({ "Name" = sdm_node.relay[count.index].relay[0].name }, var.tags, )
}
