### SDM ###
variable "SDM_API_ACCESS_KEY" {
  type      = string
  sensitive = true
}
variable "SDM_API_SECRET_KEY" {
  type      = string
  sensitive = true
}
variable "SDM_ADMIN_USER" {}

### AWS ###
variable "AWS_ACCESS_KEY_ID" {
  type      = string
  sensitive = true
}
variable "AWS_SECRET_ACCESS_KEY" {
  type      = string
  sensitive = true
}
variable "AWS_REGION" {}
