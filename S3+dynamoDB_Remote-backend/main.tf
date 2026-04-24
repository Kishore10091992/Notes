terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "srpsrp_remote_backend_s3" {
  bucket = "s3-stg-np-bsn0030651-remote-backend"
}

resource "aws_s3_bucket_versioning" "srp_remote-backend_versioning" {
  bucket = aws_s3_bucket.srpsrp_remote_backend_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "srpsrp_remote_backend_s3_sse" {
  bucket = aws_s3_bucket.srpsrp_remote_backend_s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "srpsrp_remote_backend_s3_bucket_policy" {
  bucket = aws_s3_bucket.srpsrp_remote_backend_s3.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowTerraformAccess",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.srp_role_s3_terraform.arn
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.srpsrp_remote_backend_s3.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.srpsrp_remote_backend_s3.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_dynamodb_table" "srp_terraform_state_lock" {
  name         = "ddb-stg-np-srp-bsn0030651-terraform-statelock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_role" "srp_role_s3_terraform" {
  name = "srp_terraform_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  permissions_boundary = "arn:aws:iam::987747149627:policy/StlaPermissionBoundary"
}

resource "aws_iam_policy" "srp_policy_s3_terraform" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.srpsrp_remote_backend_s3.bucket}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteIteam",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateIteam"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:209479301555:table/srp_terraform_state_lock"
      }
    ]
  })

  tags = {
    Name = "srp_policy_s3_terraform"
  }
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.srp_role_s3_terraform.name
  policy_arn = aws_iam_policy.srp_policy_s3_terraform.arn
}