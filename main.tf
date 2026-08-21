# Phase 1: Networking Module (VPC, Subnets, Gateways, Security Groups)
module "networking" {
  source = "./networking"

  aws_region           = var.aws_region
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# Phase 2: IAM Module (Roles, Policies, Permissions Boundaries)
module "iam" {
  source = "./iam"

  aws_region   = var.aws_region
  environment  = var.environment
  project_name = var.project_name
}

# Phase 3: EC2 + ASG + EBS + ECR Compute Module
module "compute_asg" {
  source = "./compute_asg"

  environment  = var.environment
  project_name = var.project_name

  # Inputs from Phase 1 (Networking)
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_subnet_ids        = module.networking.private_subnet_ids
  alb_security_group_id     = module.networking.alb_security_group_id
  compute_security_group_id = module.networking.compute_security_group_id
}

resource "aws_lb_target_group" "ecs" {
  name        = "${var.environment}-ecs-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.networking.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = local.common_tags
}

resource "aws_lb_listener_rule" "ecs" {
  listener_arn = module.compute_asg.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }

  condition {
    path_pattern {
      values = ["/ecs/*"]
    }
  }
}