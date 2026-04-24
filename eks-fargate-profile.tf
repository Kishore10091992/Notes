resource "aws_iam_role" "fargate_pod_execution_role" {
  name = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

resource "aws_iam_role_policy_attachment" "fargate_execution_policy" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_iam_role_policy" "cloudwatch_logs_inline" {
  name = ""
  role = aws_iam_role.fargate_pod_execution_role.id

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

resource "aws_eks_fargate_profile" "alb_controller" {
  cluster_name           = <eks cluster>
  fargate_profile_name   = ""
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.backend_subnet

  selector {
    namespace = ""
  }

  depends_on = [aws_eks_cluster.eks]
}