# --- IAM Role for source ep to Access Secrets Manager ---
resource "aws_iam_role" "source_ep_secrets_access_role" {
  name = "role-vdr-${var.env}-np-${var.project_id}-source-ep-secrets-access"
  description = "IAM role that allows AWS DMS to access AWS Secrets Manager for database credentials"

  # Trust policy: Allow DMS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.eu-west-1.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

# --- Attach AWS Managed Policy for Secrets Manager Access ---
resource "aws_iam_role_policy_attachment" "source_secrets_manager_access" {
  role       = aws_iam_role.source_ep_secrets_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
}

resource "aws_iam_role_policy_attachment" "source_cloudwatch_access" {
  role       = aws_iam_role.source_ep_secrets_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

# --- IAM Role for target ep to Access Secrets Manager ---
resource "aws_iam_role" "target_ep_secrets_access_role" {
  name = "role-vdr-${var.env}-np-${var.project_id}-target_ep-secrets-access"
  description = "IAM role that allows AWS DMS to access AWS Secrets Manager for database credentials"

  # Trust policy: Allow DMS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.eu-west-1.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

# --- Attach AWS Managed Policy for Secrets Manager Access ---
resource "aws_iam_role_policy_attachment" "target_secrets_manager_access" {
  role       = aws_iam_role.target_ep_secrets_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
}

resource "aws_iam_role_policy_attachment" "target_cloudwatch_access" {
  role       = aws_iam_role.target_ep_secrets_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

# --- Custom Inline Policy for Secrets Manager Access ---
resource "aws_iam_role_policy" "target_ep-custom_secrets_access" {
  name = "policy-vdr-${var.env}-np-${var.project_id}-target_ep-DMSSecretsManagerAccess"
  role = aws_iam_role.source_ep_secrets_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowSecretsManagerAccess",
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.vdradmin_secret.arn
      }
    ]
  })
}

# --- DMS Source Endpoint (IBM DB2 - On-Premises) ---
resource "aws_dms_endpoint" "source_db2" {
  endpoint_id = "ep-vdr-${var.env}-np-${var.project_id}-source-db2"
  endpoint_type = "source"
  engine_name   = "db2-zos"
  database_name   = var.database_name

  # DB2 connection details
  ssl_mode        = "none"
  server_name     = var.server_name
  port            = "446"
  username        = var.username
  password        = var.password
}

# --- DMS Target Endpoint (Aurora MySQL) ---
resource "aws_dms_endpoint" "target_aurora" {
  endpoint_id = "ep-vdr-${var.env}-np-${var.project_id}-target-aurora"
  endpoint_type = "target"
  engine_name   = "aurora"

  # Aurora connection details
  ssl_mode      = "none"
  secrets_manager_access_role_arn = aws_iam_role.target_ep_secrets_access_role.arn
  secrets_manager_arn             = aws_secretsmanager_secret.vdradmin_secret.arn
}