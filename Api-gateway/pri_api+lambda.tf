#This Is Private Apigateway
#In this private apigateway lambda is Authorizer
#Backend Integration (NLB via VPC Link) - VPC Link


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#Private API Gateway

resource "aws_api_gateway_rest_api" "vdr_pri_api_gateway" {
  name = "${var.project_id}-pri_api-gateway-${var.env}"

  endpoint_configuration {
    types = ["PRIVATE"]
  }
}

#VPC Endpoint for execute-api (Required for PRIVATE APIs)

resource "aws_vpc_endpoint" "execute_pri_api" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.frontend_subnet
  security_group_ids = [aws_security_group.vpce_sg.id]
}

#VPC Endpoint Security Group

resource "aws_security_group" "vpce_sg" {
  name        = "pri-api-sg-${var.env}-${var.project_id}-pri-apigw-vpce-sg"
  vpc_id      = var.vpc_id
  description = "Security group for API Gateway VPC Endpoint"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Resource Policy to Restrict Access to VPC Endpoint

resource "aws_api_gateway_rest_api_policy" "vdr_pri_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.vdr_pri_api_gateway.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.vdr_pri_api_gateway.id}/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceVpce": "${aws_vpc_endpoint.execute_pri_api.id}"
        }
      }
    }
  ]
}
EOF
}

#API Gateway Resources & Methods - Proxy Resource

resource "aws_api_gateway_resource" "vdr_pri_api_gateway_proxy" {
  rest_api_id = aws_api_gateway_rest_api.vdr_pri_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.vdr_pri_api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

#API Gateway Resources & Methods - Lambda Authorizer

resource "aws_api_gateway_authorizer" "vdr_request_authorizer_pri_api" {
  name                             = "${var.project_id}-authorizer-${var.env}-pri-apigateway"
  rest_api_id                      = aws_api_gateway_rest_api.vdr_pri_api_gateway.id
  type                             = "REQUEST"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300

  authorizer_uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lf-emea-ldap.arn}/invocations"
}

#API Gateway Resources & Methods - Lambda Permission for Authorizer

resource "aws_lambda_permission" "allow_pri_apigw_invoke_authorizer" {
  statement_id  = "AllowPriAPIGatewayInvokeAuthorizer-${var.project_id}-${var.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lf-emea-ldap.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.vdr_pri_api_gateway.id}/authorizers/*"
}

#API Gateway Resources & Methods - ANY Method

resource "aws_api_gateway_method" "vdr_pri_api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.vdr_pri_api_gateway.id
  resource_id   = aws_api_gateway_resource.vdr_pri_api_gateway_proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.vdr_request_authorizer_pri_api.id

  request_parameters = {
    "method.request.path.proxy"          = true
    "method.request.header.Accept"       = false
    "method.request.header.Content-Type" = false
  }
}

#Backend Integration (NLB via VPC Link) - VPC Link

resource "aws_api_gateway_vpc_link" "vdr_pri_api_gateway_vpc_link" {
  name        = "${aws_api_gateway_rest_api.vdr_pri_api_gateway.name}-vpc-link"
  target_arns = [var.nlb_arn]
}

#Backend Integration (NLB via VPC Link) - Integration

resource "aws_api_gateway_integration" "vdr_pri_api_gateway_proxy_integration" {
  rest_api_id = aws_api_gateway_rest_api.vdr_pri_api_gateway.id
  resource_id = aws_api_gateway_resource.vdr_pri_api_gateway_proxy.id
  http_method = aws_api_gateway_method.vdr_pri_api_gateway_method.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vdr_api_gateway_vpc_link.id

  uri = "${var.backend_protocol}://${var.nlb_dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy"          = "method.request.path.proxy"
    "integration.request.header.Accept"       = "method.request.header.Accept"
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
}

#Deployment

resource "aws_api_gateway_deployment" "vdr_pri_api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.vdr_pri_api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode({
      resource_id     = aws_api_gateway_resource.vdr_pri_api_gateway_proxy.id
      method          = aws_api_gateway_method.vdr_pri_api_gateway_method.http_method
      integration_id  = aws_api_gateway_integration.vdr_pri_api_gateway_proxy_integration.id
      authorizer_id   = aws_api_gateway_authorizer.vdr_request_authorizer.id
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Stage

resource "aws_api_gateway_stage" "vdr_pri_api_gateway_stage" {
  rest_api_id   = aws_api_gateway_rest_api.vdr_pri_api_gateway.id
  deployment_id = aws_api_gateway_deployment.vdr_pri_api_gateway_deployment.id
  stage_name    = var.env
}