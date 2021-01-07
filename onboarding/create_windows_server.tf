# ---------------------------------------------------------------------------- #
# Generate an RSA key pair to encrypt and decrypt the Windows password
# ---------------------------------------------------------------------------- #
resource "tls_private_key" "windows_server" {
  count = var.create_rdp ? 1 : 0
  # This resource is not recommended for production environements
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "aws_key_pair" "windows_key" {
  count      = var.create_rdp ? 1 : 0
  key_name   = "${var.prefix}-terraform-key"
  public_key = tls_private_key.windows_server[0].public_key_openssh
}
# ---------------------------------------------------------------------------- #
# Create a Security Group to allow RDP communication with the server
# ---------------------------------------------------------------------------- #
resource "aws_security_group" "windows_server" {
  count       = var.create_rdp ? 1 : 0
  name_prefix = "${var.prefix}-windows-server"
  description = "allows 3389"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [module.sdm.gateway_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ Name = "${var.prefix}-rdp" }, local.default_tags, var.tags)
}
# ---------------------------------------------------------------------------- #
# Lookup the latest Windows Server 2016 AMI and generate an EC2 instance
# ---------------------------------------------------------------------------- #
data "aws_ami" "windows_server" {
  count       = var.create_rdp ? 1 : 0
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English*"]
  }
}
resource "aws_instance" "windows_server" {
  count         = var.create_rdp ? 1 : 0
  ami           = data.aws_ami.windows_server[0].image_id
  instance_type = "t3a.medium"

  subnet_id              = local.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.windows_server[0].id]

  get_password_data = true
  key_name          = aws_key_pair.windows_key[0].key_name
  # This key is used to encrypt the windows password

  tags = merge({ Name = "${var.prefix}-rdp" }, local.default_tags, var.tags)
}
# ---------------------------------------------------------------------------- #
# Add credentials to strongDM
# ---------------------------------------------------------------------------- #
resource "sdm_resource" "windows_server" {
  count = var.create_rdp ? 1 : 0
  rdp {
    name     = "${var.prefix}-rdp"
    hostname = aws_instance.windows_server[0].private_ip
    port     = 3389
    username = "Administrator"
    password = rsadecrypt(aws_instance.windows_server[0].password_data, tls_private_key.windows_server[0].private_key_pem)
    tags     = merge({ Name = "${var.prefix}-rdp" }, local.default_tags, var.tags)
  }
}
resource "sdm_role_grant" "admin_grant_windows_server" {
  count       = var.create_rdp ? 1 : 0
  role_id     = sdm_role.admins.id
  resource_id = sdm_resource.windows_server[0].id
}
