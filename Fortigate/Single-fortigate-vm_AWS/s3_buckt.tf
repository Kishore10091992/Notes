resource "aws_s3_bucket" "s3_bucket" {
  count  = var.bucket ? 1 : 0
  bucket = var.s3-bucket-name
}

# S3 Bucket license file for BYOL License

resource "aws_s3_object" "lic1" {
  count  = var.bucket ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  key    = var.license
  source = var.license
  etag   = filemd5(var.license)
}

# S3 Bucket config file for storing fgtvm config

resource "aws_s3_object" "conf" {
  count  = var.bucket ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket[0].id
  key    = var.bootstrap-fgtvm
  content = templatefile("${var.bootstrap-fgtvm}", {
    adminsport = "${var.adminsport}"
  })
}