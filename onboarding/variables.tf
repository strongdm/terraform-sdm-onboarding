variable "tags" {
  type        = map(string)
  default     = {}
  description = "This tags will be added to both AWS and strongDM resources"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "The AWS region to deploy resources in."
}

variable "name" {
  type        = string
  default     = "strongdm"
  description = "This prefix will be added to various resource names."
}

variable "create_eks" {
  type        = bool
  default     = false
  description = "Set to true to create an EKS cluster"
}

variable "create_mysql" {
  type        = bool
  default     = true
  description = "Set to true to create an EC2 instance with mysql"
}

variable "create_rdp" {
  type        = bool
  default     = false
  description = "Set to true to create a Windows Server"
}

variable "create_http_ssh" {
  type        = bool
  default     = false
  description = "Set to true to create an EC2 instance with HTTP and SSH access"
}

variable "create_vpc" {
  type        = bool
  default     = true
  description = "Set to true to create a VPC to container the resources in this module"
}

variable "create_sdm_policy_permit_everything" {
  type        = bool
  default     = false
  description = "Set to true to create a default policy to permit everything"
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "Existing VPC ID; if set, you must also set public_subnet_ids"
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = null
  description = "Existing public subnet IDs; internet traffic will flow into these"
}

variable "private_subnet_ids" {
  type        = list(string)
  default     = null
  description = "Existing private subnet IDs to deploy resources in; if not set, defaults to public_subnet_ids"
}

variable "grant_to_existing_users" {
  type        = list(string)
  default     = []
  description = "A list of email addresses for existing accounts to be granted access to all resources."
}

variable "admin_users" {
  type        = list(string)
  default     = []
  description = "A list of email addresses that will be granted access to all resources."
}

variable "read_only_users" {
  type        = list(string)
  default     = []
  description = "A list of email addresses that will receive read only access."
}

variable "ingress_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "A list of CIDR blocks to allow ingress traffic to resources via StrongDM."
}

variable "use_gateways" {
  type        = bool
  default     = false
  description = "Set to true to deploy legacy gateways instead of a proxy cluster."
}
