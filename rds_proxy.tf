resource "aws_iam_role" "rds_proxy_role" {
  name = "rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "rds.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

resource "aws_iam_policy" "rds_proxy_secrets_policy" {
  name        = "rds-proxy-secrets-policy"
  description = "Allows RDS Proxy to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = var.rds_admin_credential_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy_secrets_attachment" {
  role       = aws_iam_role.rds_proxy_role.name
  policy_arn = aws_iam_policy.rds_proxy_secrets_policy.arn
}

resource "aws_security_group" "rds_proxy_sg" {
  name        = "rds-proxy-sg"
  description = "Security group for RDS Proxy"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]  # Allow Lambda to connect
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_proxy" "rds_proxy" {
  name                   = "lambda-rds-proxy"
  engine_family          = "MYSQL"  # Use "POSTGRESQL" if using PostgreSQL
  role_arn               = aws_iam_role.rds_proxy_role.arn
  vpc_security_group_ids = [aws_security_group.rds_proxy_sg.id]
  vpc_subnet_ids         = var.backend_subnet

  auth {
    description = "RDS Proxy Auth"
    auth_scheme = "SECRETS"
    secret_arn  = <rds_secrete manager_arn>
    iam_auth    = "DISABLED"
  }
}

resource "aws_db_proxy_target" "rds_proxy_target" {
  db_proxy_name = aws_db_proxy.rds_proxy.name
  target_group_name = "default"
  db_cluster_identifier = <rds_cluster_identifier>
}