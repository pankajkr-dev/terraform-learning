# ==========================================
# 1. CLOUDWATCH LOG GROUP
# ==========================================
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.environment}-app"
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
  name = "${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ==========================================
# 3. IAM ROLES & POLICY ATTACHMENTS
# ==========================================
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-ecs-execution-role"

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

# Attached secrets policy directly to the role managed inside module.iam
resource "aws_iam_role_policy_attachment" "ecs_task_secrets" {
  role       = module.iam.ecs_task_role_name
  policy_arn = module.iam.app_secrets_policy_arn
}

# ==========================================
# 4. SECURITY GROUP FOR FARGATE TASKS
# ==========================================
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Allow HTTP traffic to ECS tasks"
  vpc_id      = module.networking.vpc_id

  ingress {
    description     = "HTTP Inbound"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.networking.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-tasks-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==========================================
# 5. TASK DEFINITION
# ==========================================
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = module.iam.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "web-app"
      image     = var.container_image
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
          "awslogs-region"        = var.aws_region
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
  name            = "${var.environment}-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "web-app"
    container_port   = 80
  }

  network_configuration {
    subnets          = module.networking.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_lb_listener_rule.ecs
  ]
}