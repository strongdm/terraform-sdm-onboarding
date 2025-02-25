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
variable "ecs_cluster_name" {
  description = "The name of the ECS cluster to deploy proxies into."
  type        = string
}
variable "vpc_id" {
  description = "VPC ID is used to assign security groups in the correct network"
  type        = string
}
variable "traffic_port" {
  description = "Port for strongDM proxy cluster to listen for incoming connections"
  type        = number
  default     = 443
}
variable "worker_count" {
  description = "Number of workers to run in the proxy cluster"
  type        = number
  default     = 1
}
variable "worker_cpu" {
  type        = number
  default     = 2048
  description = "Amount of vCPU each worker should have."
}
variable "worker_memory" {
  type        = number
  default     = 4096
  description = "Amount of memory each worker should have."
}
variable "private_subnet_ids" {
  description = "strongDM proxy workers will be deployed into the subnets provided"
  type        = list(string)
  default     = null
}
variable "public_subnet_ids" {
  description = "The NLB will be deployed into the subnets provided"
  type        = list(string)
  default     = null
}
variable "ingress_cidr_blocks" {
  description = "A list of CIDR blocks from which to allow ingress traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
