# ==========================================
# 1. CLOUDWATCH LOG GROUP
# ==========================================
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/dev-app"
  retention_in_days = 7

  tags = {
    Environment = "dev"
    Project     = "ContainerizedWebPlatform"
  }
}

# ==========================================
# 2. ECS CLUSTER
# ==========================================
resource "aws_ecs_cluster" "main" {
  name = "dev-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ==========================================
# 3. IAM ROLES & POLICY ATTACHMENTS
# ==========================================
resource "aws_iam_role" "ecs_execution_role" {
  name = "dev-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "dev-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = module.iam.app_secrets_policy_arn
}

# ==========================================
# 4. SECURITY GROUP FOR FARGATE TASKS
# ==========================================
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "dev-ecs-tasks-sg"
  description = "Allow HTTP traffic to ECS tasks"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "HTTP Inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-ecs-tasks-sg"
  }
}

# ==========================================
# 5. TASK DEFINITION
# ==========================================
resource "aws_ecs_task_definition" "app" {
  family                   = "dev-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "web-app"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ==========================================
# 6. ECS SERVICE (STANDALONE FARGATE)
# ==========================================
resource "aws_ecs_service" "main" {
  name            = "dev-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.networking.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy
  ]
}