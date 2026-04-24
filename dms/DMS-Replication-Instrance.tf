resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "dms.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  permissions_boundary = var.stlaPermissionBoundary
}

resource "aws_iam_role_policy_attachment" "dms_vpc_policy" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_iam_role_policy_attachment" "dms_logs_policy" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}

resource "aws_cloudwatch_log_group" "dms_log_group" {
  name              = "/aws/dms/${var.env}-${var.project_id}-logs"
  retention_in_days = 30
}

# --- DMS Subnet Group ---
resource "aws_dms_replication_subnet_group" "dms_rep_subnet_group" {
  replication_subnet_group_id = "dms-vdr-${var.env}np-${var.project_id}-subnet-group"
  replication_subnet_group_description = "DMS subnet group for replication instance"
  subnet_ids = var.frontend_subnet
}

resource "aws_security_group" "dms-rep-security-group" {
 name = "dms-sg-${var.env}-np-${var.project_id}-dms-rep"
 vpc_id = var.vpc_id

 ingress {
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }

 egress {
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
}

# --- DMS Replication Instance ---
resource "aws_dms_replication_instance" "dms_instance" {
  replication_instance_id = "dms-vdr-${var.env}-np-${var.project_id}-replication-instance"
  replication_instance_class   = var.replication_instance_class
  allocated_storage            = var.allocated_storage
  publicly_accessible          = false
  multi_az                     = false
  auto_minor_version_upgrade   = true
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms_rep_subnet_group.id
  vpc_security_group_ids       = [aws_security_group.dms-rep-security-group.id]
  apply_immediately            = true
}