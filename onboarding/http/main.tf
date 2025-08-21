# =============================================================================
# HTTP/SSH RESOURCES MODULE
# =============================================================================
# This module creates a Linux EC2 instance with both HTTP web server and SSH
# access through StrongDM. It provides a demonstration environment for testing
# web application access and SSH connectivity via the StrongDM proxy network.
#
# Features:
#   - Amazon Linux 2023 EC2 instance with Apache web server
#   - SSH access using StrongDM certificate-based authentication
#   - HTTP access through StrongDM for web application testing
#   - Security groups restricting access to StrongDM proxies only
#   - Sample website deployment for demonstration purposes
#
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
# AMI DATA SOURCE
# -----------------------------------------------------------------------------
# Retrieves the latest Amazon Linux 2023 AMI for EC2 instance deployment
# Amazon Linux 2023 provides modern packages, security updates, and performance optimizations

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Latest AL2023 AMI for x86_64 architecture
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
# SECURITY GROUP FOR WEB SERVER
# -----------------------------------------------------------------------------
# Creates security group allowing HTTP and SSH access from StrongDM proxies only
# Implements network-level security and principle of least privilege

resource "aws_security_group" "web_page" {
  name_prefix = "${var.name}-web-page"
  description = "HTTP/SSH server security group - allows access from StrongDM proxies only"
  vpc_id      = var.vpc_id

  # Outbound rules (allow all egress for package updates, external API calls)
  egress {
    description = "All outbound traffic for system updates and external communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name    = "${var.name}-http-sg",
    Purpose = "HTTP/SSH server access control"
  }, var.tags)
}

# -----------------------------------------------------------------------------
# SECURITY GROUP RULES
# -----------------------------------------------------------------------------
# Define specific ingress rules allowing HTTP and SSH access from StrongDM proxies only

# HTTP access rule (port 80)
resource "aws_security_group_rule" "allow_80" {
  type        = "ingress"
  description = "HTTP access from StrongDM proxy instances"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  # Allow access only from StrongDM proxy security group
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.web_page.id
}

# SSH access rule (port 22)
resource "aws_security_group_rule" "allow_http_ssh" {
  type        = "ingress"
  description = "SSH access from StrongDM proxy instances"

  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  # Allow SSH access only from StrongDM proxy security group
  source_security_group_id = var.security_group
  security_group_id        = aws_security_group.web_page.id
}

# -----------------------------------------------------------------------------
# EC2 WEB SERVER INSTANCE
# -----------------------------------------------------------------------------
# Creates Amazon Linux 2023 instance with Apache web server and SSH access
# Deployed in private subnet with security groups restricting access to StrongDM proxies

resource "aws_instance" "web_page" {
  # AMI and instance configuration
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro" # Burstable performance, cost-effective for testing

  # Network configuration
  subnet_id              = var.subnet_id # Private subnet for enhanced security
  vpc_security_group_ids = [aws_security_group.web_page.id]

  # Disable public IP assignment for security
  associate_public_ip_address = false

  # Instance metadata service configuration (IMDSv2 for security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Require IMDSv2 tokens
    http_put_response_hop_limit = 2
  }

  # Root volume encryption for data protection
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8 # GB - minimal size for cost efficiency
    encrypted             = true
    delete_on_termination = true
  }

  # User data script for web server setup and SSH key installation
  # Template includes Apache installation and StrongDM SSH CA public key setup
  user_data = templatefile("${path.module}/templates/http_install/http_install.tftpl", {
    SSH_PUB_KEY = var.ssh_pubkey
  })

  tags = merge({
    Name = "${var.name}-http",
    Type = "web-server",
    OS   = "amazon-linux-2023"
  }, var.tags)
}

# =============================================================================
# STRONGDM RESOURCE REGISTRATION
# =============================================================================
# Registers both HTTP and SSH access to the EC2 instance as StrongDM resources
# Users can access the web application and server management through StrongDM

# -----------------------------------------------------------------------------
# HTTP RESOURCE REGISTRATION
# -----------------------------------------------------------------------------
# Registers web server for HTTP access through StrongDM
# Creates secure tunnel for web application access without exposing server to internet

resource "sdm_resource" "web_page" {
  http_no_auth {
    # Resource identification in StrongDM
    name = "${var.name}-http"

    # HTTP connection configuration
    url              = "http://${aws_instance.web_page.private_ip}" # Private IP access only
    default_path     = "/"                                          # Default landing page
    healthcheck_path = "/"                                          # Health check endpoint for StrongDM monitoring
    subdomain        = "simple-web-page"                            # StrongDM subdomain for access

    # StrongDM routing configuration
    proxy_cluster_id = var.proxy_cluster_id

    # Resource tagging
    tags = merge({
      Name         = "${var.name}-http",
      AccessType   = "http",
      ResourceType = "web-server"
    }, var.tags)
  }
}

# -----------------------------------------------------------------------------
# SSH RESOURCE REGISTRATION
# -----------------------------------------------------------------------------
# Registers EC2 instance for SSH access using certificate-based authentication
# Provides secure shell access for server administration and troubleshooting

resource "sdm_resource" "ssh_ec2" {
  ssh_cert {
    # Resource identification in StrongDM
    name = "${var.name}-ssh-al2023"

    # SSH connection configuration
    username = "ec2-user"                       # Default user for Amazon Linux 2023
    hostname = aws_instance.web_page.private_ip # Private IP for secure access
    port     = 22                               # Standard SSH port

    # StrongDM routing configuration
    proxy_cluster_id = var.proxy_cluster_id

    # Resource tagging
    tags = merge({
      Name         = "${var.name}-ssh",
      AccessType   = "ssh",
      ResourceType = "linux-server",
      OS           = "amazon-linux-2023"
    }, var.tags)
  }
}
