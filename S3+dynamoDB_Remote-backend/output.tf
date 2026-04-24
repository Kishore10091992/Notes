output "s3_arn" {
  description = "s3 bucket arn"
  value       = aws_s3_bucket.vdr_remote-backend_s3.arn
}

output "dynamodb_arn" {
  description = "dynamodb arn"
  value       = aws_dynamodb_table.vdr_terraform_state_lock.arn
}

output "iam_role_arn" {
  description = "iam role arn"
  value       = aws_iam_role.vdr_role_s3_terraform.arn
}

output "iam_policy_arn" {
  description = "iam policy arn"
  value       = aws_iam_policy.vdr_policy_s3_terraform.arn
}