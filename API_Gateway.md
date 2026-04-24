# Api Id of HTTP API

aws apigatewayv2 get-apis \
  --query "Items[*].[ApiId,Name,ProtocolType]" \
  --output table

To get the invoke URL

aws apigatewayv2 get-api \
  --api-id <API_ID> \
  --query "ApiEndpoint" \
  --output text

List routes

aws apigatewayv2 get-routes --api-id <API_ID> \
  --query "Items[*].[RouteKey,Target]" \
  --output table

To get listener deatils

aws elbv2 describe-listeners \
  --load-balancer-arn <loadbalancer-arn>

To describe target group health

aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>

Invoke the API from CloudShell

Simple GET request

curl -i https://<api-id>.execute-api.<region>.amazonaws.com/<stage>/path

POST request

curl -i -X POST \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}' \
  https://<api-id>.execute-api.<region>.amazonaws.com/<stage>/path

