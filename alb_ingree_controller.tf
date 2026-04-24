data "aws_eks_cluster" "eks" {
  name = <need to map eks name>
}

data "aws_eks_cluster_auth" "eks" {
  name = <need to map eks name>
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da0afd10df6"
  ]
}

resource "aws_iam_role" "lb_controller_role" {
  name = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

resource "aws_iam_role_policy" "aws_lb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMInline"
  role   = aws_iam_role.lb_controller_role.name
  policy = file("${path.module}/iam_policy.json")
}

resource "kubernetes_service_account" "aws_lb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller_role.arn
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.0"

  
  set {
    name  = "clusterName"
    value = <need to map eks name>
  }
  
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}