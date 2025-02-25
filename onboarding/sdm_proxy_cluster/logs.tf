resource "aws_cloudwatch_log_group" "this" {
  name_prefix       = "sdm-proxy-"
  retention_in_days = 3

  tags = var.tags
}
