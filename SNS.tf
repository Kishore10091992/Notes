resource "aws_sns_topic" "alarm_sns_topic" {
  name = "cloudwatch-alarm-topic"
}

# SNS Topic Subscription for Email
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarm_sns_topic.arn
  protocol  = "email"
  endpoint  = <provide_email-id>  # First email
}