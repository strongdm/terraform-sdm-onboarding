resource "aws_iam_role" "this_task_execution" {
  name_prefix = "sdm-proxy-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "this_task_execution" {
  name_prefix = "sdm-proxy-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "*"
      },

      {
        Action = "ssm:GetParameter*"
        Effect = "Allow"
        Resource = [
          aws_ssm_parameter.secret_key.arn,
        ],
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this_task_execution" {
  role       = aws_iam_role.this_task_execution.name
  policy_arn = aws_iam_policy.this_task_execution.arn
}

# ==========

resource "aws_iam_role" "this_task" {
  name_prefix = "sdm-proxy-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "this_task" {
  name_prefix = "sdm-proxy-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ExecuteCommand"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this_task" {
  role       = aws_iam_role.this_task.name
  policy_arn = aws_iam_policy.this_task.arn
}
