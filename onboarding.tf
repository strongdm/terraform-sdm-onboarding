module "strongdm_onboarding" {
  source = "./onboarding"

  # Name will be added to resource names
  name = "terraform-sdm"

  # EKS resource takes approximately 20 min
  # create_eks               = false

  # Mysql resources take approximately 15 min
  # create_mysql             = true

  # RDP resource takes approximately 10 min
  # create_rdp               = false

  # HTTP/SSH resource takes approximately 5 min
  # NOTE: Before creating HTTP resources, set up TLS here https://app.strongdm.com/app/datasources/websites
  # create_http_ssh = false

  # VPC creation takes approximately 5 min
  # If set to false the default VPC will be used instead unless an explicit vpc_id is passed in
  # optionally subnet_ids can also be added to select a subset of subnets
  # create_vpc = true

  # StrongDM Proxy Ingress CIDR blocks default to open to the world.
  # ingress_cidr_blocks = ["0.0.0.0/0"]

  # Tags will be added to strongDM and AWS resources.
  # tags = {}
}
