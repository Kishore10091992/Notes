# Get lambda configuration back-up in file

aws lambda get-function-configuration \
  --function-name <lambda-name> \
  > lambda-config.json

# Get lambda environment variable in file

aws lambda get-function-configuration \
  --function-name <lambda-name> \
  --query "Environment.Variables" \
  > lambda-env-vars.json

# Get lambda VPC details in file

aws lambda get-function-configuration \
  --function-name <lambda-name> \
  --query "{Subnets:VpcConfig.SubnetIds, SGs:VpcConfig.SecurityGroupIds}" \
  > dev-vpc.json

# One‑Shot Script (Role + All Policies)

FUNCTION_NAME=<lambda-function-name>

ROLE_NAME=$(aws lambda get-function-configuration \
  --function-name $FUNCTION_NAME \
  --query 'Role' \
  --output text | awk -F'/' '{print $NF}')

echo "Lambda Role: $ROLE_NAME"

echo "Managed Policies:"
aws iam list-attached-role-policies --role-name $ROLE_NAME

echo "Inline Policies:"
aws iam list-role-policies --role-name $ROLE_NAME

# List Resource‑Based Triggers (Most Important)

aws lambda get-policy --function-name <lambda-function-name>

# Get Event Source Mappings

aws lambda list-event-source-mappings \
  --function-name <lambda-function-name>

# One‑Command Summary Script

FUNCTION_NAME=<lambda-name>

echo "=== Resource-based triggers ==="
aws lambda get-policy --function-name $FUNCTION_NAME

echo "=== Poll-based triggers (SQS/Kinesis/DynamoDB) ==="
aws lambda list-event-source-mappings --function-name $FUNCTION_NAME

# Add eventbridge Scheduled rule as trigger

aws lambda add-permission \
  --function-name "<lambda-name" \
  --statement-id "AllowEventBridgeInvoke" \
  --action "lambda:InvokeFunction" \
  --principal events.amazonaws.com \
  --source-arn "<eventbridge Scheduled rule arn>"

