#This Is Regional Apigateway
#In this Regional apigateway lambda is Authorizer
#Backend Integration (NLB via VPC Link) - VPC Link

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#Regional API Gateway

resource "aws_api_gateway_rest_api" "vdr_api_gateway" {
  name = "${var.project_id}-api-gateway-${var.env}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "vdr_api_gateway_proxy" {
  rest_api_id = aws_api_gateway_rest_api.vdr_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.vdr_api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_authorizer" "vdr_request_authorizer" {
  name                             = "${var.project_id}-authorizer-${var.env}"
  rest_api_id                      = aws_api_gateway_rest_api.vdr_api_gateway.id
  type                             = "REQUEST"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300

  # Directly wire your Lambda resource ARN here:
  authorizer_uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lf-emea-ldap.arn}/invocations"
}

resource "aws_lambda_permission" "allow_apigw_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer-${var.project_id}-${var.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lf-emea-ldap.arn
  principal     = "apigateway.amazonaws.com"

  # Grant for this REST API's authorizers
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.vdr_api_gateway.id}/authorizers/*"
}

resource "aws_api_gateway_method" "vdr_api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.vdr_api_gateway.id
  resource_id   = aws_api_gateway_resource.vdr_api_gateway_proxy.id
  http_method   = "ANY"

  # Attach custom Lambda authorizer
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.vdr_request_authorizer.id

  api_key_required = false

  # Request parameters:
  # - Path param 'proxy' is required (true)
  # - Headers Accept and Content-Type are present but not required (false)
  request_parameters = {
    "method.request.path.proxy"          = true
    "method.request.header.Accept"       = false
    "method.request.header.Content-Type" = false
  }

  depends_on = [
    aws_api_gateway_authorizer.vdr_request_authorizer,
    aws_lambda_permission.allow_apigw_invoke_authorizer
  ]
}

resource "aws_api_gateway_vpc_link" "vdr_api_gateway_vpc_link" {
  name        = "${aws_api_gateway_rest_api.vdr_api_gateway.name}-vpc-link"
  target_arns = [var.nlb_arn]
}

resource "aws_api_gateway_integration" "vdr_api_gateway_proxy_integration" {
  rest_api_id = aws_api_gateway_rest_api.vdr_api_gateway.id
  resource_id = aws_api_gateway_resource.vdr_api_gateway_proxy.id
  http_method = aws_api_gateway_method.vdr_api_gateway_method.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vdr_api_gateway_vpc_link.id

  # Endpoint URL (VPC proxy integration to NLB)
  uri = "${var.backend_protocol}://${var.nlb_dns_name}/{proxy}"

  # Map method request to integration:
  request_parameters = {
    "integration.request.path.proxy"          = "method.request.path.proxy"
    "integration.request.header.Accept"       = "method.request.header.Accept"
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }

  # REST integrations are buffered by default; no flag needed for "Buffered".
  # Timeout = default (no explicit timeout_milliseconds)

  depends_on = [aws_api_gateway_vpc_link.vdr_api_gateway_vpc_link]
}

resource "aws_api_gateway_deployment" "vdr_api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.vdr_api_gateway.id

  # Trigger redeployment on changes
  triggers = {
    redeployment = sha1(jsonencode({
      resource_id     = aws_api_gateway_resource.vdr_api_gateway_proxy.id
      method          = aws_api_gateway_method.vdr_api_gateway_method.http_method
      integration_id  = aws_api_gateway_integration.vdr_api_gateway_proxy_integration.id
      authorizer_id   = aws_api_gateway_authorizer.vdr_request_authorizer.id
      stage_cache_off = false
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.vdr_api_gateway_proxy_integration,
    aws_api_gateway_authorizer.vdr_request_authorizer
  ]
}

resource "aws_api_gateway_stage" "vdr_api_gateway_stage" {
  rest_api_id   = aws_api_gateway_rest_api.vdr_api_gateway.id
  deployment_id = aws_api_gateway_deployment.vdr_api_gateway_deployment.id
  stage_name    = var.env

     cache_cluster_enabled = false
}