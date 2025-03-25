resource "aws_ecs_service" "this" {
  name        = "${var.name}-proxy"
  launch_type = "FARGATE"

  cluster         = var.ecs_cluster_name
  task_definition = "${aws_ecs_task_definition.this.id}:${aws_ecs_task_definition.this.revision}"

  desired_count                      = var.worker_count
  force_new_deployment               = true
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  wait_for_steady_state = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "proxy"
    container_port   = local.container_proxy_port
  }

  propagate_tags = "SERVICE"
  tags           = var.tags

  depends_on = [aws_lb_listener.this]

  lifecycle {
    postcondition {
      condition     = self.task_definition == "${aws_ecs_task_definition.this.id}:${aws_ecs_task_definition.this.revision}"
      error_message = "The service did not reach the steady state at the requested version"
    }
  }
}
