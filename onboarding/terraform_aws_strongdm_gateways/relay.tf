#################
# Create strongDM gateway and store token
#################
resource "sdm_node" "relay" {
  count = local.relay_count

  relay {
    name = "${var.sdm_node_name}-relay-${count.index}"
  }
}
resource "aws_ssm_parameter" "relay" {
  count = local.relay_count

  type  = "SecureString"
  value = sdm_node.relay[count.index].relay.0.token
  name  = "/strongdm/relay/${sdm_node.relay[count.index].relay.0.name}/token"

  overwrite = true
  key_id    = var.encryption_key

  tags = merge({ "Name" = sdm_node.relay[count.index].relay.0.name }, var.tags, )

  depends_on = [aws_ssm_parameter.gateway]
}
#################
# Instance configuration 
#################
resource "aws_instance" "relay" {
  count = local.relay_count

  ami           = data.aws_ami.amazon_linux_2.image_id
  instance_type = var.dev_mode ? "t3.micro" : "t3.medium"

  user_data = <<USERDATA
#!/bin/bash -xe
curl -J -O -L https://app.strongdm.com/releases/cli/linux && unzip sdmcli* && rm -f sdmcli*
sudo ./sdm install --relay --token="${aws_ssm_parameter.relay[count.index].value}"
USERDATA

  key_name   = var.ssh_key
  monitoring = var.detailed_monitoiring

  credit_specification {
    # Prevents CPU throttling and potential performance issues with Gateway
    cpu_credits = "unlimited"
  }

  # Relay Attributes 
  subnet_id              = var.relay_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.this["relay"].id]

  lifecycle {

    # Prevents Instance from respawning when Amazon Linux 2 is updated
    ignore_changes = [ami]

    # Used to prevent EIP from failing to associate 
    # https://github.com/terraform-providers/terraform-provider-aws/issues/2689
    create_before_destroy = true
  }

  tags = merge({ "Name" = sdm_node.relay[count.index].relay.0.name }, var.tags, )
}