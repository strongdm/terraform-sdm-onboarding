output "sdm_gateway_ids" {
  value = {
    for instance in aws_instance.gateway :
    instance.tags.Name => instance.id
  }
}
output "sdm_gateway_ips" {
  value = {
    for instance in aws_instance.gateway :
    instance.tags.Name => instance.public_ip
  }
}
output "sdm_relay_ids" {
  value = {
    for instance in aws_instance.relay :
    instance.tags.Name => instance.id
  }
}
output gateway_security_group_id {
  value       = local.create_gateway ? aws_security_group.this["gateway"].id : "No security group defined"
  description = "The ID of the gateway security group if created"
}
output relay_security_group_id {
  value       = local.create_relay ? aws_security_group.this["relay"].id : "No security group defined"
  description = "The ID of the relay security group if created"
}