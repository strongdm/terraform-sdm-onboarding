module "strongdm_onboarding" {
  source = "./onboarding"

  # Prefix will be added to resource names
  prefix = "terraform-sdm"

  # EKS resources take approximately 20 min
  # create_eks               = true
  # Mysql resources take approximately 5 min
  # create_mysql             = true
  # RDP resources take approximately 10 min
  # create_rdp               = true
  # HTTP resources take approximately 5 min
  # NOTE: Before creating HTTP resources, set up TLS here https://app.strongdm.com/app/datasources/websites
  # create_http              = false
  # SSH resources take approximately 5 min
  # create_ssh              = true
  # Gateways take approximately 5 min
  create_strongdm_gateways = true

  # VPC creation takes approximately 5 min
  # If set to false the default VPC will be used instead
  create_vpc = true

  # Tags will be added to strongDM and AWS resources.
  tags = { usage = "strongdm_demo" }
}
