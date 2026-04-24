# List Managed Policies Attached to the Role

aws iam list-attached-role-policies \
  --role-name <role-name>

aws iam get-role-policy \
  --role-name <role-name> \
  --policy-name InlineDynamoDBAccess