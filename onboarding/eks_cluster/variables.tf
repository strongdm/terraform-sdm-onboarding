variable "name" {
  description = "This name is applied to resources where applicable, e.g. titles and tags."
  type        = string
  default     = "strongDM"
}
variable "tags" {
  description = "Tags to be applied to reasources created by this module"
  type        = map(string)
  default     = {}
}
variable "proxy_cluster_id" {
  description = "The proxy cluster to assign the StrongDM resource to"
  type        = string
}
variable "worker_role_arn" {
  description = "IAM Role ARN of proxy workers, which will receive permission to connect to EKS"
  type        = string
}
variable "worker_security_group_id" {
  description = "Security group ID which StrongDM proxy workers are assigned to"
  type        = string
}
variable "vpc_id" {
  description = "ID of the VPC to deploy in"
  type        = string
}
variable "subnet_ids" {
  description = "IDs of subnets to deploy in"
  type        = list(string)
}
