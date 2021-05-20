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
  # Kibana resources take approximately 15 min
  # create_kibana            = true
  # Gateways take approximately 5 min
  # create_strongdm_gateways = true

  # VPC creation takes approximately 5 min
  # If set to false the default VPC will be used instead
  # create_vpc = true


  # List of existing users to grant resources to
  # NOTE: These emails must exactly match existing users in strongDM or an error will occur
  # NOTE: An error will occur if these users are already assigned to a role in strongDM
  grant_to_existing_users = [
    var.SDM_ADMIN_USER
  ]

  # New accounts to create with access to all resources
  # admin_users = [
  #   "admin1@example.com", 
  #   "admin2@example.com", 
  #   "admin3@example.com", 
  # ]

  # New accounts to create with read-only permissions
  # read_only_users = [
  #   "user1@example.com",
  #   "user2@example.com",
  #   "user3@example.com",
  # ]

  # Tags will be added to strongDM and AWS resources.
  # tags = {}
}
