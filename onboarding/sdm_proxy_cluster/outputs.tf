output "id" {
  value       = sdm_node.this.id
  description = "The ID of the proxy cluster"
}
output "worker_security_group_id" {
  value       = aws_security_group.this.id
  description = "The ID of the security group which proxy workers are assigned to"
}
output "worker_role_arn" {
  value       = aws_iam_role.this_task.arn
  description = "IAM Role ARN of the workers"
}
