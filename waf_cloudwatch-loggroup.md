1. Create a log group

aws logs create-log-group \
  --log-group-name aws-waf-logs-<log group name> \
  --region <region>

2. Put a resource policy

aws logs put-resource-policy \
  --region <region> \
  --policy-name AWSWAFLogsDeliveryResourcePolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AWSWAFLogsDelivery",
        "Effect": "Allow",
        "Principal": { "Service": "delivery.logs.amazonaws.com" },
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": "<log-group-arn>",
        "Condition": {
          "StringEquals": { "aws:SourceAccount": "<account-id>" },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:wafv2:<region>:<account-id>:regional/webacl/*"
          }
        }
      }
    ]
  }'

3. Enable WAF logging with the new destination ARN

aws wafv2 put-logging-configuration \
  --region eu-west-1 \
  --logging-configuration "{
    \"ResourceArn\": \"<web-acl-arn>\",
    \"LogDestinationConfigs\": [\"arn:aws:logs:<region>:<account-id>:log-group:aws-waf-logs-<log group name>\"]
  }"