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
