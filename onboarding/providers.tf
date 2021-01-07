terraform {
  required_version = ">= 0.12.26"
  required_providers {
    aws        = ">= 3.0.0"
    sdm        = ">= 1.0.12"
    random     = ">= 2.0.0"
    local      = ">= 1.0.0"
    null       = ">= 2.0.0"
    kubernetes = ">= 1.11.0"
    template   = ">= 2.1.0"
  }
}