# CloudWatch Alarm for RDS threshold
resource "aws_cloudwatch_metric_alarm" "aurora_acu_utilization" {
  alarm_name          = "aurora-acu-utilization-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ACUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"  # Trigger when ACU utilization exceeds 80%
  alarm_description   = "This alarm monitors Aurora Serverless v2 ACU utilization."
  alarm_actions       = [aws_sns_topic.alarm_sns_topic.arn]  # Optional: SNS topic for notifications

  # Filter for the specific Aurora cluster
  dimensions = {
    DBClusterIdentifier = <db_cluster-name>
  }
}