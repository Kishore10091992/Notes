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

resource "aws_iam_role" "eks-sa" {
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
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:<namespace>:<service-account-name>"
            "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

resource "aws_iam_role_policy_attachment" "sa_policy" {
  role   = aws_iam_role.eks-sa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "kubernetes_service_account" "vdr-app-rest-sa" {
  provider = kubernetes
  metadata {
    name      = ""
    namespace = ""

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks-sa.arn
    }
  }
}