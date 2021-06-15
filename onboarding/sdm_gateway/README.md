# strongDM Gateways and Relays terraform module

This module uses the following resources:

## strongDM
* [Gateway](https://strongdm.com/docs/admin-guide/gateways/)
* [Relay](https://strongdm.com/docs/admin-guide/relays/)

## AWS
* [ssm_parameter](https://www.terraform.io/docs/providers/aws/r/ssm_parameter.html)
* [instance](https://www.terraform.io/docs/providers/aws/r/instance.html)
* [elastic_ip](https://www.terraform.io/docs/providers/aws/r/eip.html)
* [network_interface](https://www.terraform.io/docs/providers/aws/r/network_interface.html)
* [security_group](https://www.terraform.io/docs/providers/aws/r/security_group.html)

## Requirements
| Name | Version |
|------|---------|
| terraform | ~> 0.12.6 |
| aws | ~> 2.53 |
| strongDM | ~> 1.0 |

## Usage

H.A. gateways in the same subnet
~~~
module "sdm" {
  source = "github.com/peteroneilljr/terraform_aws_strongdm_gateways"

  sdm_node_name = "dev-env-public"

  deploy_vpc_id = module.vpc.vpc_id
  gateway_subnet_ids = [ 
    module.vpc.public_subnets[0], 
    module.vpc.public_subnets[0] 
  ]
}
~~~

Add relay to private subnet with tags
~~~
module "sdm" {
  source = "github.com/peteroneilljr/terraform_aws_strongdm_gateways"

  sdm_node_name = "dev-env-private"
  
  deploy_vpc_id = module.vpc.vpc_id
  relay_subnet_ids = [
    module.vpc.private_subnets[0]
  ]

  tags = {
    env = "private subnet"
    firewall = "egress only"
  }
}
~~~

Full Options Deployment 
~~~
module "sdm" {
  source = "github.com/peteroneilljr/terraform_aws_strongdm_gateways"

  sdm_node_name = "dev-env"
  deploy_vpc_id = module.vpc.vpc_id

  gateway_listen_port  = 5000
  gateway_subnet_ids = [module.vpc.public_subnets[0]]

  relay_subnet_ids = [module.vpc.private_subnets[0]]

  ssh_key    = aws_key_pair.sdm_key.key_name
  ssh_source = "0.0.0.0/0"

  encryption_key = aws_kms_key.sdm_gateway.key_id

  detailed_monitoiring = true
  enable_cpu_alarm = true
  dns_hostnames = false
  dev_mode = false

  enable_module = true

  tags     = var.default_tags
}
~~~

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| sdm_node_name | Logical name used as a prefix for gateway/relay resources and their dependencies. | `string` | `strongDM` | no |
| deploy_vpc_id | Resource ID of the VPC where all resources are to be deployed | `string` | `null` | yes |
| gateway_listen_port | TCP port strongDM clients will connect to, inbound rule is created on security groups for this port. | `num` | `5000` | no |
| gateway_subnet_ids | A stronDM gateway will be created per subnet ID provided, the same ID can be provided more than once for H.A. | `list(string)` | [] | no |
| relay_subnet_ids | A strongDM relay will be create per subnet ID provider, this subnet will need an egress route to the strongDM gateway listen address. | `list(string)` | [] | no |
| ssh_key | Add a SSH public key for SSH access to the EC2 instances hosting the gateways and relays. A key cannot be provided after the creation event. | `string` | `null` | no |
| ssh_source | If ssh_key is set, an inbound rule is created on the gateway security group. Add a CIDR range here to restrict source IP address. | `string` | `0.0.0.0/0` | no |
| encryption_key | Provide a KMS customer managed key ID to encrypt your strongDM tokens with. If left blank the default amazon managed key will used instead. | `string` | `null` | no |
| detailed_monitoiring | Enables detailed monitoring on all instances. | `bool` | `false` | no |
| enable_cpu_alarm | When enabled a CloudWatch alarm is created for each instance. Threshold is greater than 75% utilization for 2 rounds of 5 minutes. | `bool` | `false` | no |
| dns_hostnames | The strongDM gateways will look for the public dns name to use for the strongDM gateway hostname, set to false to switch to IP address. | `bool` | `true` | no |
| dev_mode | When enabled t3.micros are used instead of t3.mediums, this is not recommended for production environments. | `bool` | `false` | no |
| enable_module | A conditional create option, when set to false no resources will be created. | `bool` | `true` | no |
| tags | Any tags provided will be passed along to any resources that are created. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| sdm_gateway_ids | Map of gateway names and instance IDs | 
| sdm_gateway_public_ips | Map of gateway names and instance IP addresses |
| sdm_relay_ids | Map of relay names and instance IDs |
