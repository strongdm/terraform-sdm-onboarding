#################
# CloudWatch Alarm
#################
resource "aws_cloudwatch_metric_alarm" "this" {
  count = var.enable_cpu_alarm ? local.node_count : 0

  alarm_name                = "cpu-over-75-${concat(aws_instance.gateway.*.tags.Name, aws_instance.relay.*.tags.Name)[count.index]}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "This SDM gateway is overutilized"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = concat(aws_instance.gateway.*.id, aws_instance.relay.*.id)[count.index]
  }
}