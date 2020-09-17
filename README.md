# Terraform Onboarding

## Example

~~~hcl
module "strongdm_onboarding" {
  source = "git::https://github.com/strongdm/terraform-sdm-onboarding.git"

  # Prefix will be added to resource names
  prefix = "education"

  # EKS resoruces take approximately 20 min
  create_eks               = true
  # Mysql resources take approximately 5 min
  create_mysql             = true
  # RDP resources take approximately 10 min
  create_rdp               = true
  # HTTP resources take approximately 5 min
  create_http              = true
  # Kibana resources take approximately 15 min
  create_kibana            = true
  # Gateways take approximately 5 min
  create_strongdm_gateways = true

  # Leave variables set to null to create resources in default VPC.
  vpc_id     = null
  subnet_ids = null

  # List of existing users to grant resources to
  # NOTE: An error will occur if these users are already assigned to a role
  grant_to_existing_users = [
    "user+prod@strongdm.com",
  ]

  # New accounts to create with access to all resources
  admin_users = [
    "user+admin1@strongdm.com", 
    "user+admin2@strongdm.com", 
    "user+admin3@strongdm.com", 
  ]

  # New accounts to create with read-only permissions
  read_only_users = [
    "user+read1@strongdm.com",
    "user+read2@strongdm.com",
    "user+read3@strongdm.com",
  ]

  # Tags will be added to strongDM and AWS resources.
  tags = {}
}
~~~
