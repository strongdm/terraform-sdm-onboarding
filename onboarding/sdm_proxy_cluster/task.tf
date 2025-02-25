resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.this_task_execution.arn
  task_role_arn            = aws_iam_role.this_task.arn

  cpu    = var.worker_cpu
  memory = var.worker_memory

  container_definitions = jsonencode([
    {
      name      = "proxy"
      image     = "public.ecr.aws/strongdm/relay:latest"
      essential = true

      cpu    = var.worker_cpu
      memory = var.worker_memory

      portMappings = [{
        protocol      = "tcp"
        containerPort = local.container_proxy_port
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          mode                  = "non-blocking"
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-stream-prefix = "proxy_cluster"
          awslogs-region        = data.aws_region.current.name
        }
      }

      environment = [
        {
          name  = "SDM_DOCKERIZED"
          value = "true"
        },
        {
          name  = "SDM_BIND_ADDRESS"
          value = ":${local.container_proxy_port}"
        },
      ]

      secrets = [
        {
          name  = "SDM_PROXY_CLUSTER_ACCESS_KEY"
          value = sdm_proxy_cluster_key.this.id
        },
        {
          name      = "SDM_PROXY_CLUSTER_SECRET_KEY"
          valueFrom = aws_ssm_parameter.secret_key.arn
        }
      ]
    }
  ])

  tags = var.tags
}
