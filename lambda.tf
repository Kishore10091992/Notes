# -----------------------------------------------------
# IAM - Assume role policy for Lambda
# -----------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name                  = ""
  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  description           = "Execution role for lf-ldap"
  force_detach_policies = true
  permissions_boundary = var.stlaPermissionBoundary
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "secrets_ro" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"
}

# Inline ENI policy for Lambda-in-VPC
data "aws_iam_policy_document" "eni_inline" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eni_inline" {
  name   = "lf-ldap-eni-inline"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.eni_inline.json
}

# -----------------------------------------------------
# Stub ZIP so Lambda can be created (you will push real code manually later)
# -----------------------------------------------------
data "archive_file" "stub_zip" {
  type        = "zip"
  output_path = "${path.module}/.lf-ldap-stub.zip"

  source {
    filename = "index.js"
    content  = <<-JS
      // Minimal stub handler to allow Lambda resource creation in Stage
      exports.handler = async (event) => {
        return { statusCode: 200, body: JSON.stringify({ ok: true, env: "stage", stub: true }) };
      };
    JS
  }
}

# -----------------------------------------------------
# Lambda Function (Stage)
# -----------------------------------------------------
resource "aws_lambda_function" "lf-emea-ldap" {
  function_name = ""
  role          = aws_iam_role.lambda_role.arn

  handler       = "index.handler"
  runtime       = "nodejs24.x"
  architectures = ["arm64"]

  memory_size = "128"
  timeout     = "3"

  # Provide stub ZIP to satisfy Lambda creation
  filename         = data.archive_file.stub_zip.output_path
  source_code_hash = data.archive_file.stub_zip.output_base64sha256

  # VPC attachment (use Stage subnets/SG)
  vpc_config {
    subnet_ids         = var.frontend_subnet
    security_group_ids = [var.nlb_sg_id]
  }

  # Keep runtime patched automatically
  #runtime_management_config {
   # update_runtime_on = "Auto"
  #}

  # Let you update code manually (Console/CLI) without Terraform re-uploading
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      s3_bucket,
      s3_key,
      image_uri,
    ]
  }
}