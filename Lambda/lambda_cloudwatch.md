#  Create CloudWatch Log Group

aws logs create-log-group \
  --log-group-name "$LOG_GROUP_NAME" \
  --region $REGION

# Set Log Retention Period

aws logs put-retention-policy \
  --log-group-name "$LOG_GROUP_NAME" \
  --retention-in-days 30 \
  --region $REGION

# Create Log Stream Manually

aws logs create-log-stream \
  --log-group-name "$LOG_GROUP_NAME" \
  --log-stream-name manual-test-stream \
  --region $REGION

# Verify Log Group Exists

aws logs describe-log-groups \
  --log-group-name-prefix "/aws/lambda/$LAMBDA_NAME" \
  --region $REGION

# Lambda IAM Role Check

aws lambda get-function \
  --function-name $LAMBDA_NAME \
  --query 'Configuration.Role'

# View Logs via CloudShell

aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP_NAME" \
  --order-by LastEventTime \
  --descending \
  --region $REGION

# Fetch latest logs

aws logs get-log-events \
  --log-group-name "$LOG_GROUP_NAME" \
  --log-stream-name "<log-stream-name>"