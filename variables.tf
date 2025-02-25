### SDM ###
variable "SDM_API_ACCESS_KEY" {
  type      = string
  sensitive = true
  default   = null
}

variable "SDM_API_SECRET_KEY" {
  type      = string
  sensitive = true
  default   = null
}

### AWS ###
variable "AWS_ACCESS_KEY_ID" {
  type      = string
  sensitive = true
  default   = null
}

variable "AWS_SECRET_ACCESS_KEY" {
  type      = string
  sensitive = true
  default   = null
}

variable "REGION_AWS" {
  type = string
}
