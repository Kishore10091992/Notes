resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-eu-west-1-ireland"
  retention_in_days = var.waf-log-retention
}

resource "aws_cloudwatch_log_resource_policy" "waf_delivery" {
  policy_name     = "AWSWAFLogsDeliveryResourcePolicy"
  policy_document = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSWAFLogsDelivery",
        Effect    = "Allow",
        Principal = { Service = "delivery.logs.amazonaws.com" },
        Action    = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource  = aws_cloudwatch_log_group.waf_logs.arn,
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account-id
          },
          ArnLike = {
            # For Regional Web ACLs
            "aws:SourceArn" = var.web_acl_arn
          }
        }
      }
    ]
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn          = var.web_acl_arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  depends_on = [
    aws_cloudwatch_log_resource_policy.waf_delivery,
    aws_cloudwatch_log_group.waf_logs
  ]
}