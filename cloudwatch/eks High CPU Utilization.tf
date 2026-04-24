# CloudWatch Alarm for eks High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "eks-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ContainerInsights"
  namespace           = "app-rest"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 90   # CPU threshold 80%
  alarm_description   = "Triggered when EKS CPU Utilization exceeds 80% for 5 minutes"
  dimensions = {
    ClusterName = <eks-name>
    ServiceName = <eks-name>
  }
  alarm_actions = [aws_sns_topic.alarm_sns_topic.arn]
}