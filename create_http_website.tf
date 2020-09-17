# ---------------------------------------------------------------------------- #
# Create an EC2 instance
# ---------------------------------------------------------------------------- #
data "aws_ami" "amazon_linux_2" {
  count       = var.create_http ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
resource "aws_instance" "web_page" {
  count         = var.create_http ? 1 : 0
  ami           = data.aws_ami.amazon_linux_2[0].id
  instance_type = "t3.micro"

  subnet_id = local.subnet_ids[1]

  # Configures a simple HTTP web page 
  user_data = <<-EOF
  #!/bin/bash -xe

  # add sdm public key
  cat <<SDM_KEY | tee /etc/ssh/sdm_ca.pub
  ${data.sdm_ssh_ca_pubkey.this_key.public_key}
  SDM_KEY
  cat <<SDM_TRUST | sudo tee -a /etc/ssh/sshd_config
  TrustedUserCAKeys /etc/ssh/sdm_ca.pub
  SDM_TRUST
  systemctl restart sshd

  # setup apache
  yum update -y
  amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
  yum install -y httpd mariadb-server
  systemctl start httpd
  systemctl enable httpd
  usermod -a -G apache ec2-user
  chown -R ec2-user:apache /var/www
  chmod 2775 /var/www
  find /var/www -type d -exec chmod 2775 {} \;
  find /var/www -type f -exec chmod 0664 {} \;
  echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
  EOF

  tags = merge({ Name = "${var.prefix}-http" }, local.default_tags, var.tags)
}
# ---------------------------------------------------------------------------- #
# Add the web page to strongDM
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "web_page" {
  count = var.create_http ? 1 : 0
  http_no_auth {
    name             = "${var.prefix}-http"
    url              = "http://${aws_instance.web_page[0].private_dns}"
    default_path     = "/phpinfo.php"
    healthcheck_path = "/phpinfo.php"
    subdomain        = "simple-web-page"

    tags = merge({ Name = "${var.prefix}-http" }, local.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "admin_grant_web_page" {
  count = var.create_http ? 1 : 0
  role_id = sdm_role.admins.id
  resource_id = sdm_resource.web_page[0].id
}
resource "sdm_role_grant" "read_only_grant_web_page" {
  count = var.create_http ? 1 : 0
  role_id = sdm_role.read_only.id
  resource_id = sdm_resource.web_page[0].id
}
# ---------------------------------------------------------------------------- #
# Access the EC2 instance with strongDM over SSH
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "ssh_ec2" {
  count = var.create_http ? 1 : 0
  ssh_cert {
    # dependant on https://github.com/strongdm/issues/issues/1701
    name     = "${var.prefix}-ssh-ca"
    username = "ec2-user"
    hostname = aws_instance.web_page[0].private_dns
    port     = 22
    tags     = merge({ Name = "${var.prefix}-http" }, local.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "admin_grant_ssh_ec2" {
  count = var.create_http ? 1 : 0
  role_id = sdm_role.admins.id
  resource_id = sdm_resource.ssh_ec2[0].id
}