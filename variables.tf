### SDM ###
variable "SDM_API_ACCESS_KEY" {
  type      = string
  sensitive = true
}

variable "SDM_API_SECRET_KEY" {
  type      = string
  sensitive = true
}

variable "SDM_ADMINS_EMAILS" {
  type = string
}

### AWS ###
variable "AWS_ACCESS_KEY_ID" {
  type      = string
  sensitive = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  type      = string
  sensitive = true
}

variable "REGION_AWS" {
  type    = string
  default = null
}
