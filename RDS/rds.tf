#In this terraform script secrete manager, kms and rds is created
#secrete manager and KMS are integrated with RDS

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "key" {
  description             = ""
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow RDS to use the key",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow account admins full access",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "random_password" "password" {
 length = 16
 special = true
 override_special   = "!#$%^&*()-_=+[]|:;<>?,."
}

resource "aws_secretsmanager_secret" "secret" {
 name = ""
}

resource "aws_secretsmanager_secret_version" "secret_version" {
 secret_id = aws_secretsmanager_secret.secret.id

 secret_string = jsonencode ({
  username = ""
  password = random_password.password.result
 })
}

# Data sources to retrieve the secrets 
data "aws_secretsmanager_secret_version" "admin_secret_version" { 
  secret_id = aws_secretsmanager_secret.secret.id
  depends_on = [aws_secretsmanager_secret_version.admin_secret_version]
}

data "aws_secretsmanager_secret_version" "dev_secret_version" { 
  secret_id = aws_secretsmanager_secret.secret.id
  depends_on = [aws_secretsmanager_secret_version.dev_secret_version]
} 

locals { 
  admin_credentials = jsondecode(data.aws_secretsmanager_secret_version.admin_secret_version.secret_string)  
  dev_credentials = jsondecode(data.aws_secretsmanager_secret_version.dev_secret_version.secret_string)
} 

# Get all subnet details to extract CIDR blocks
data "aws_subnet" "subnet_info" {
  for_each = toset(var.backend_subnet)
  id       = each.value
}
# Extract CIDR blocks from subnets
locals {
  allowed_cidr_blocks = [for s in data.aws_subnet.subnet_info : s.cidr_block]
}

# Security Group for Aurora Serverless RDS
resource "aws_security_group" "aurora_sg" {
  vpc_id      = var.vpc_id  # Replace with your VPC ID

  ingress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }

 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }

 tags = {
  Name = ""
 }
}

resource "aws_db_subnet_group" "rds_subnet_group" { 
  subnet_ids  = var.backend_subnet

  tags = { 
    Name = "aurora-serverless-v2-subnet-group" 
  } 
} 

resource "aws_iam_role" "rds_monitoring" {
  name = ""
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "monitoring.rds.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_rds_cluster" "_db" { 
  cluster_identifier      = "aurora-serverless-cluster" 
  engine                  = "aurora-mysql" 
  allow_major_version_upgrade = true
  engine_version          = "8.0"  # Ensure this is a supported version for Serverless v2 
  master_username         = local.admin_credentials["username"] 
  master_password         = local.admin_credentials["password"] 
  database_name           = "" 
  engine_mode             = "provisioned"  # Adjust based on your needs 
  storage_encrypted       = true 
  kms_key_id              = aws_kms_key.key.arn
  skip_final_snapshot     = true 
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name 
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]  # Replace with your actual security group IDs 
  backup_retention_period       = var.backup_retention_period
  preferred_backup_window       = "18:30-19:30"
  copy_tags_to_snapshot         = true
  apply_immediately              = true
  monitoring_interval  = 10
  monitoring_role_arn  = aws_iam_role.rds_monitoring.arn

    serverlessv2_scaling_configuration  { 
      min_capacity = var.rds_min_acu  # Adjust based on your needs 
      max_capacity = var.rds_max_acu
    } 
}  

resource "aws_rds_cluster_instance" "aurora_instance" { 
  identifier         = "aurora-serverless-instance" 
  cluster_identifier = aws_rds_cluster._db.id 
  instance_class     = "db.serverless"  # Serverless  instance class 
  engine             = aws_rds_cluster._db.engine 
  engine_version     = aws_rds_cluster._db.engine_version 
  publicly_accessible = false
  apply_immediately   = true
  performance_insights_enabled     = true
  performance_insights_kms_key_id  = aws_kms_key.key.arn
  lifecycle {
    ignore_changes = [
      monitoring_interval,
      monitoring_role_arn
    ]
  }
}