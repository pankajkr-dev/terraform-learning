# ==========================================
# 1. IAM ROLE FOR EKS CLUSTER CONTROL PLANE
# ==========================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# ==========================================
# 2. EKS CONTROL PLANE CLUSTER
# ==========================================
resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/${var.environment}/cluster"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.31"

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    subnet_ids              = module.networking.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_logs
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group_rule" "rds_from_eks" {
  type                     = "ingress"
  security_group_id        = module.networking.rds_security_group_id
  source_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  description              = "Allow PostgreSQL from EKS worker traffic"
}

# ==========================================
# 3. IAM ROLE FOR EKS WORKER NODE GROUP
# ==========================================
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.environment}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# ==========================================
# 4. EKS MANAGED WORKER NODE GROUP
# ==========================================
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-eks-worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = module.networking.private_subnet_ids

  instance_types = ["t3.medium"]
  ami_type       = "AL2023_x86_64_STANDARD"

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "kubernetes_deployment_v1" "app" {
  metadata {
    name = "${var.environment}-app"
    labels = {
      app         = "${var.environment}-app"
      environment = var.environment
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "${var.environment}-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.environment}-app"
        }
      }

      spec {
        container {
          name  = "web-app"
          image = var.container_image

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [aws_eks_node_group.main]
}

resource "kubernetes_service_v1" "app" {
  metadata {
    name = "${var.environment}-app"
  }

  spec {
    selector = {
      app = "${var.environment}-app"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.app]
}