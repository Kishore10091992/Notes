resource "aws_iam_policy" "dms_cloudwatch_logging_policy" {
  name        = "DMSCloudWatchLoggingPolicy"
  description = "Allows DMS to publish logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_logging_policy_attach" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = aws_iam_policy.dms_cloudwatch_logging_policy.arn
}

# --- AWS DMS Replication Task ---
resource "aws_dms_replication_task" "dms_task" {
  replication_task_id = "db2-to-aurora-task"
  migration_type               = var.migration_type
  replication_instance_arn     = aws_dms_replication_instance.dms_instance.replication_instance_arn
  source_endpoint_arn          = aws_dms_endpoint.source_db2.endpoint_arn
  target_endpoint_arn          = aws_dms_endpoint.target_aurora.endpoint_arn
  table_mappings               = file("table-mappings.json")
  replication_task_settings    = file("task-settings.json")
}

resource "aws_cloudwatch_log_group" "dms_task_logs" {
  name              = "/aws/dms/task-logs"
  retention_in_days = 30
}