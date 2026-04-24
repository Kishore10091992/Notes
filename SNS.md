#  Create an SNS Topic

aws sns create-topic --name <sns-topic-name>

# Create Email Subscription

aws sns subscribe \
  --topic-arn <sns-topic-arn> \
  --protocol email \
  --notification-endpoint <your-email@example.com>

# Create SMS Subscription

aws sns subscribe \
  --topic-arn <sns-topic-arn> \
  --protocol sms \
  --notification-endpoint +919XXXXXXXXX

# Publish a Message to the SNS Topic

aws sns publish \
  --topic-arn <sns-topic-arn> \
  --message "Hello from AWS CloudShell

# Tag the SNS Topic

aws sns tag-resource \
  --resource-arn <sns-topic-arn> \
  --tags Key=Environment,Value=Dev Key=Owner,Value=Kishore

# Delete the SNS Topic (Cleanup)

aws sns delete-topic \
  --topic-arn <sns-topic-arn>

# List SNS Topics (Verify Creation)

aws sns list-topics