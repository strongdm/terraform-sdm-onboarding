# =============================================================================
# WINDOWS SERVER MODULE
# =============================================================================
# This module creates a Windows Server EC2 instance with RDP access through
# StrongDM. It provides a demonstration environment for testing Windows-based
# applications and remote desktop connectivity via the StrongDM proxy network.
#
# Features:
#   - Windows Server 2022 EC2 instance
#   - RDP access through StrongDM for secure remote desktop
#   - Security groups restricting access to StrongDM proxies only
#   - Automatic password generation and encryption
#   - Private subnet deployment for enhanced security
#
# Security Considerations:
#   - Instance deployed in private subnet with no direct internet access
#   - RDP access restricted to StrongDM proxy security groups only
#   - Administrator password encrypted using generated RSA key pair
#   - Instance metadata service (IMDSv2) enabled for security
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
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# RSA KEY PAIR GENERATION
# -----------------------------------------------------------------------------
# Generates RSA key pair for Windows Administrator password encryption
# SECURITY NOTE: Not recommended for production - use AWS KMS or external key management

resource "tls_private_key" "windows_server" {
  # WARNING: This resource stores the private key in Terraform state
  # For production deployments, use AWS KMS or external key management
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "windows_key" {
  key_name   = "${var.name}-terraform-key"
  public_key = tls_private_key.windows_server.public_key_openssh

  tags = merge({
    Name    = "${var.name}-windows-keypair",
    Purpose = "Windows server password encryption"
  }, var.tags)
}

# -----------------------------------------------------------------------------
# WINDOWS SERVER SECURITY GROUP
# -----------------------------------------------------------------------------
# Creates security group allowing RDP access from StrongDM proxies only
# Implements network-level security and principle of least privilege

resource "aws_security_group" "windows_server" {
  name_prefix = "${var.name}-windows-server"
  description = "Windows Server security group - allows RDP from StrongDM proxies only"
  vpc_id      = var.vpc_id

  # Inbound rules - allow RDP access from StrongDM proxies only
  ingress {
    description     = "RDP access from StrongDM proxy instances"
    from_port       = 3389 # Remote Desktop Protocol port
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [var.security_group] # StrongDM proxy security group
  }

  # Outbound rules - allow all egress for Windows Updates and software installation
  egress {
    description = "All outbound traffic for Windows updates and system operations"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name    = "${var.name}-rdp-sg",
    Purpose = "Windows Server RDP access control"
  }, var.tags)
}

# -----------------------------------------------------------------------------
# WINDOWS SERVER AMI LOOKUP
# -----------------------------------------------------------------------------
# Retrieves the latest Windows Server 2022 AMI for EC2 instance deployment
# Windows Server 2022 provides modern security features and performance improvements

data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base*"] # Latest Windows Server 2022 Full edition
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] # Hardware Virtual Machine for better performance
  }

  filter {
    name   = "state"
    values = ["available"] # Only consider available AMIs
  }
}

# -----------------------------------------------------------------------------
# WINDOWS SERVER EC2 INSTANCE
# -----------------------------------------------------------------------------
# Creates Windows Server 2022 instance with RDP access through StrongDM
# Deployed in private subnet with security groups restricting access to StrongDM proxies

resource "aws_instance" "windows_server" {
  # AMI and instance configuration
  ami           = data.aws_ami.windows_server.image_id
  instance_type = "t3a.medium" # Medium instance for Windows Server performance requirements

  # Network configuration
  subnet_id              = var.subnet_id # Private subnet for enhanced security
  vpc_security_group_ids = [aws_security_group.windows_server.id]

  # Disable public IP assignment for security
  associate_public_ip_address = false

  # Instance metadata service configuration (IMDSv2 for security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Require IMDSv2 tokens
    http_put_response_hop_limit = 2
  }

  # Root volume configuration with encryption
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30 # GB - minimum for Windows Server 2022
    encrypted             = true
    delete_on_termination = true
  }

  # Windows password encryption configuration
  get_password_data = true                              # Enable encrypted password retrieval
  key_name          = aws_key_pair.windows_key.key_name # Key pair for password encryption

  tags = merge({
    Name = "${var.name}-rdp",
    OS   = "windows-server-2022",
    Type = "windows-server"
  }, var.tags)
}

# =============================================================================
# STRONGDM WINDOWS SERVER RESOURCE REGISTRATION
# =============================================================================
# Registers the Windows Server as a StrongDM RDP resource for secure remote desktop access
# Creates encrypted connection through StrongDM proxy network

resource "sdm_resource" "windows_server" {
  rdp {
    # Resource identification in StrongDM
    name = "${var.name}-rdp"

    # RDP connection configuration
    hostname = aws_instance.windows_server.private_ip # Private IP for secure access
    port     = 3389                                   # Remote Desktop Protocol standard port
    username = "Administrator"                        # Windows built-in administrator account

    # Password decryption using generated RSA private key
    # AWS encrypts the Administrator password with the public key from the key pair
    password = rsadecrypt(aws_instance.windows_server.password_data, tls_private_key.windows_server.private_key_pem)

    # StrongDM routing configuration
    proxy_cluster_id = var.proxy_cluster_id

    # Resource tagging
    tags = merge({
      Name         = "${var.name}-rdp",
      AccessType   = "rdp",
      ResourceType = "windows-server",
      OS           = "windows-server-2022"
    }, var.tags)
  }
}
