# Create an IAM Role to assign to the FortiGate VM instance

resource "aws_iam_role" "fgtvm-role" {
  count = var.bucket ? 1 : 0
  name  = var.iam-role-fgtvm

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Sid = ""
      }
    ]
  })
}

# IAM Policy for FortiGate to access the S3 Buckets

resource "aws_iam_role_policy" "fortigate-iam_role_policy" {
  count  = var.bucket ? 1 : 0
  name   = var.iam-policy-fgtvm
  role   = aws_iam_role.fgtvm-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
   {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.s3_bucket[0].id}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.s3_bucket[0].id}/*"]
    }
  ]
}
EOF
}

# Assign the IAM Profile to the FortiGate instance

resource "aws_iam_instance_profile" "fortigate" {
  count = var.bucket ? 1 : 0
  name  = var.fgtiamprofile

  role = aws_iam_role.fgtvm-role.name
}