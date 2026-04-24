# CloudWatch Alarm for eks High Memory Utilization
resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "eks-high-memory-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "ContainerInsights"
  period              = 60   # 1 minute
  statistic           = "Average"
  threshold           = 90   # Memory threshold 90%
  alarm_description   = "Triggered when EKS Memory Utilization exceeds 90%"
  dimensions = {
    ClusterName = <eks-name>
    ServiceName = <eks-name>
  }
  alarm_actions = [aws_sns_topic.alarm_sns_topic.arn]
}