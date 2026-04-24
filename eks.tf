resource "aws_iam_role" "eks_cluster_role" {
  name = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  permissions_boundary = var.stlaPermissionBoundary
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks" {
  name     = ""
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = var.backend_subnet
  }

  version = "1.34"
}

resource "aws_eks_addon" "coredns" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "coredns"
  addon_version            = "v1.12.4-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  configuration_values = jsonencode({
    replicaCount = 2
    resources = {
      limits = {
        cpu    = "100m"
        memory = "150Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "150Mi"
      }
    }
  })
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "eks-pod-identity-agent"
  addon_version            = "v1.3.9-eksbuild.5"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_addon_version" "kube_proxy_latest" {
  addon_name         = "kube-proxy"
  kubernetes_version = data.aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name   = aws_eks_cluster.eks.name
  addon_name     = "kube-proxy"
  addon_version  = data.aws_eks_addon_version.kube_proxy_latest.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}