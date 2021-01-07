#################
# Create strongDM gateway and store token
#################
resource "sdm_node" "gateway" {
  count = local.gateway_count

  gateway {
    name           = "${var.sdm_node_name}-gateway-${count.index}"
    listen_address = "${var.dns_hostnames ? aws_eip.gateway[count.index].public_dns : aws_eip.gateway[count.index].public_ip}:${var.gateway_listen_port}"
    bind_address   = "0.0.0.0:${var.gateway_listen_port}"
  }
}
resource "aws_ssm_parameter" "gateway" {
  count = local.gateway_count

  type  = "SecureString"
  value = sdm_node.gateway[count.index].gateway.0.token
  name  = "/strongdm/gateway/${sdm_node.gateway[count.index].gateway.0.name}/token"

  overwrite = true
  key_id    = var.encryption_key

  tags = merge({ "Name" = "${sdm_node.gateway[count.index].gateway.0.name}" }, var.tags, )
}

#################
# Instance configuration 
#################
resource "aws_eip" "gateway" {
  count             = local.gateway_count
  network_interface = aws_network_interface.gateway[count.index].id
}
resource "aws_network_interface" "gateway" {
  count = local.gateway_count

  subnet_id       = var.gateway_subnet_ids[count.index]
  security_groups = [aws_security_group.this["gateway"].id]

  tags = merge({ "Name" = "${var.sdm_node_name}-nic-${count.index}" }, var.tags, )
}

resource "aws_instance" "gateway" {
  count = local.gateway_count

  ami           = data.aws_ami.amazon_linux_2.image_id
  instance_type = var.dev_mode ? "t3.micro" : "t3.medium"

  user_data = <<USERDATA
#!/bin/bash -xe
curl -J -O -L https://app.strongdm.com/releases/cli/linux && unzip sdmcli* && rm -f sdmcli*
sudo ./sdm install --relay --token="${aws_ssm_parameter.gateway[count.index].value}"
USERDATA

  key_name   = var.ssh_key
  monitoring = var.detailed_monitoiring

  credit_specification {
    # Prevents CPU throttling and potential performance issues with Gateway
    cpu_credits = "unlimited"
  }

  dynamic "network_interface" {
    for_each = count.index < local.gateway_count ? [1] : []
    content {
      network_interface_id = aws_network_interface.gateway[count.index].id
      device_index         = 0
    }
  }

  lifecycle {

    # Prevents Instance from respawning when Amazon Linux 2 is updated
    ignore_changes = [ami]

    # Used to prevent EIP from failing to associate 
    # https://github.com/terraform-providers/terraform-provider-aws/issues/2689
    # create_before_destroy = true
  }

  tags = merge({ "Name" = "${sdm_node.gateway[count.index].gateway.0.name}" }, var.tags, )
}