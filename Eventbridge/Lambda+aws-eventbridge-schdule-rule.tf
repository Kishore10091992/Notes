resource "aws_cloudwatch_event_rule" "schedule_rule_ASRF003Z" {
  name                = "ASRF003Z"
  description         = "Scheduled rule to trigger Lambda for batch job"
  schedule_expression = "cron(0 20 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target_schedule_rule_ASRF003Z" {
  rule      = aws_cloudwatch_event_rule.schedule_rule_ASRF003Z.name
  target_id = "lambda"

  arn = aws_lambda_function.batch_job.arn

  # Pass parameters as JSON input
  input = jsonencode({
    "CUSTOM_PARAMETER" = "ASRF003Z"
  })
}

resource "aws_lambda_permission" "allow_eventbridge_ASRF003Z" {
  statement_id  = "AllowExecutionFromEventBridgeForASRF003Z"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.batch_job.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_rule_ASRF003Z.arn
}