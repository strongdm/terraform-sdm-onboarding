# =============================================================================
# ECS TASK DEFINITION FOR STRONGDM PROXY CLUSTER
# =============================================================================
# Defines the ECS Fargate task for running StrongDM proxy containers.
# This task definition specifies container configuration, resource allocation,
# networking, logging, and security settings for the proxy cluster.
#
# Key Configuration:
#   - Fargate serverless container execution
#   - StrongDM relay container image from ECR Public
#   - CloudWatch logging integration
#   - Secure environment variable handling via SSM
#   - Network configuration for proxy traffic routing
# =============================================================================

resource "aws_ecs_task_definition" "this" {
  # Task family name for versioning and identification
  family = var.name

  # Network configuration for Fargate compatibility
  network_mode             = "awsvpc" # Required for Fargate, provides dedicated ENI
  requires_compatibilities = ["FARGATE"]

  # IAM roles for task execution and runtime permissions
  execution_role_arn = aws_iam_role.this_task_execution.arn # Pulls container images, writes logs
  task_role_arn      = aws_iam_role.this_task.arn           # Runtime permissions for proxy operations

  # Resource allocation for Fargate task
  cpu    = var.worker_cpu    # vCPU units (256, 512, 1024, etc.)
  memory = var.worker_memory # Memory in MB, must be compatible with CPU allocation

  # Container configuration for StrongDM proxy
  container_definitions = jsonencode([
    {
      # Container identification
      name      = "proxy"
      image     = "public.ecr.aws/strongdm/relay:latest" # Official StrongDM relay image
      essential = true                                   # Task fails if this container stops

      # Resource allocation (must match task-level allocation for single-container tasks)
      cpu    = var.worker_cpu
      memory = var.worker_memory

      # Network port configuration for proxy traffic
      portMappings = [{
        protocol      = "tcp"
        containerPort = local.container_proxy_port # Internal proxy port
        # hostPort is omitted - Fargate automatically assigns and manages ports
      }]

      # CloudWatch logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          mode                  = "non-blocking" # Non-blocking prevents log congestion
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-stream-prefix = "proxy_cluster" # Log stream naming prefix
        awslogs-region = data.aws_region.current.id }
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
        {
          name  = "SDM_PROXY_CLUSTER_ACCESS_KEY"
          value = sdm_proxy_cluster_key.this.id
        },
      ]

      secrets = [
        {
          name      = "SDM_PROXY_CLUSTER_SECRET_KEY"
          valueFrom = aws_ssm_parameter.secret_key.arn
        },
      ]
    }
  ])

  tags = var.tags
}
