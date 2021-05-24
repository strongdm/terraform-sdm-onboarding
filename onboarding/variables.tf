variable tags {
  type        = map(string)
  default     = {}
  description = "This tags will be added to both AWS and strongDM resources"
}

variable prefix {
  type        = string
  default     = "strongdm"
  description = "This prefix will be added to various resource names."
}

variable create_eks {
  type        = bool
  default     = false
  description = "Set to true to create an EKS cluster"
}

variable create_mysql {
  type        = bool
  default     = true
  description = "Set to true to create an EC2 instance with mysql"
}

variable create_rdp {
  type        = bool
  default     = false
  description = "Set to true to create a Windows Server"
}

variable create_http {
  type        = bool
  default     = false
  description = "Set to true to create an EC2 instance with HTTP resources"
}

variable create_ssh {
  type        = bool
  default     = true
  description = "Set to true to create an EC2 instances with SSH access"
}

variable create_kibana {
  type        = bool
  default     = false
  description = "Set to true to create an ElasticSearch cluster and Kibana dashboard"
}

variable create_strongdm_gateways {
  type        = bool
  default     = true
  description = "Set to true to create a pair of strongDM gateways"
}

variable create_vpc {
  type        = bool
  default     = true
  description = "Set to true to create a VPC to container the resources in this module"
}

variable grant_to_existing_users {
  type        = list(string)
  default     = []
  description = "A list of email addresses for existing accounts to be granted access to all resources."
}

variable admin_users {
  type        = list(string)
  default     = []
  description = "A list of email addresses that will be granted access to all resources."
}

variable read_only_users {
  type        = list(string)
  default     = []
  description = "A list of email addresses that will receive read only access."
}
