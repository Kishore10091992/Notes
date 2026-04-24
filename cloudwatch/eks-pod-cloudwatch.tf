resource "aws_iam_role" "eks_fargate_pods_cloudwatch_log" {
  name               = ""
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

#need to add this policy in all the fargate profile iam role which is created under eks cluster

resource "aws_iam_role_policy" "cloudwatch_logs_inline" {
  name = ""
  role = aws_iam_role.eks_fargate_pods_cloudwatch_log.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_eks_fargate_profile" "eks_cloudwatch_logs" {
  cluster_name           = <eks cluster>
  fargate_profile_name   = ""
  pod_execution_role_arn = aws_iam_role.eks_fargate_pods_cloudwatch_log.arn
  subnet_ids             = var.backend_subnet

  selector {
    namespace = "aws-observability"
  }

  depends_on = [aws_eks_cluster.eks]
}

resource "kubernetes_namespace" "aws_observability" {
  metadata {
    name = "aws-observability"
    labels = {
      aws-observability = "enabled"
    }
  }
}

resource "kubernetes_manifest" "aws_eks_logging" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "aws-logging"
      namespace = "aws-observability"
    }
    data = {
      "output.conf" = <<-EOT
        [OUTPUT]
            Name              cloudwatch_logs
            Match             kube.*
            region            ${var.region}
            log_group_name    /aws/eks/${aws_eks_cluster.eks.name}
            log_stream_prefix from-fluent-bit-
            auto_create_group true
      EOT
    }
  }
}