resource "aws_acm_certificate" "prd_cert" {
  provider         = aws.us_east_1  # Use the us-east-1 provider
  domain_name = "var.primary_domain"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "app_rest" {
  certificate_authority_arn = ""
  domain_name               = ""
  key_algorithm             = "RSA_2048"
  subject_alternative_names = [""]
}