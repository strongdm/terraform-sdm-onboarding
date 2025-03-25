variable "sdm_node_name" {
  description = "This name is applied to resources where applicable, e.g. titles and tags."
  type        = string
  default     = "strongDM"
}
variable "deploy_vpc_id" {
  description = "VPC IP is used to assign security groups in the correct network"
  type        = string
}
variable "gateway_listen_port" {
  description = "Port for strongDM gateways to listen for incoming connections"
  type        = number
  default     = 5000
}
variable "gateway_subnet_ids" {
  description = "strongDM gateways will be deployed into subnets provided"
  type        = list(string)
  default     = []
}

variable "gateway_ingress_ips" {
  description = "A list of ingress IPs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "relay_subnet_ids" {
  description = "strongDM relays will be deployed into subnets provided"
  type        = list(string)
  default     = []
}
variable "ssh_key" {
  description = "Creates EC2 instances with public key for access"
  type        = string
  default     = null
}
variable "ssh_source" {
  description = "Restric SSH access, default is allow from anywahere"
  type        = string
  default     = "0.0.0.0/0"
}
variable "tags" {
  description = "Tags to be applied to reasources created by this module"
  type        = map(string)
  default     = {}
}
variable "dev_mode" {
  description = "Enable to deploy smaller sized instances for testing"
  type        = bool
  default     = false
}
variable "detailed_monitoring" {
  description = "Enable detailed monitoring all instances created"
  type        = bool
  default     = false
}
variable "dns_hostnames" {
  description = "Use IP address or DNS hostname of EIP to create strongDM gateways"
  type        = bool
  default     = true
}
variable "encryption_key" {
  description = "Specify a customer key to use for SSM parameter store encryption."
  type        = string
  default     = null
}
variable "enable_cpu_alarm" {
  description = "CloudWatch alarm: 75% cpu utilization for 10 minutes."
  type        = bool
  default     = false
}

#################
# Sources latest Amazon Linux 2 AMI ID
#################
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

#################
# Locals
#################
locals {
  create_relay   = local.relay_count > 0 ? true : false
  create_gateway = local.gateway_count > 0 ? true : false

  gateway_count = length(var.gateway_subnet_ids)
  relay_count   = length(var.relay_subnet_ids)
  node_count    = local.gateway_count + local.relay_count
}
