terraform {
  required_version = ">= 0.12.26"
  required_providers {
    aws = ">= 3.0.0"
    sdm        = {
      source = "strongdm/sdm"
      version = ">= 1.0.12"
    }
  }
}
provider aws {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}
variable AWS_REGION {}
variable AWS_ACCESS_KEY_ID {}
variable AWS_SECRET_ACCESS_KEY {}

provider sdm {
  api_access_key = var.SDM_API_ACCESS_KEY
  api_secret_key = var.SDM_API_SECRET_KEY
}
variable SDM_API_ACCESS_KEY {}
variable SDM_API_SECRET_KEY {}

locals {
  admin_user = var.SDM_ADMIN_USER
}
variable SDM_ADMIN_USER {}
