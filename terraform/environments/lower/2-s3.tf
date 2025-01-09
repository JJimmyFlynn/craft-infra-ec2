resource "random_id" "s3_suffix" {
  byte_length = 8
}

module "web_files_bucket" {
  source     = "../../modules/s3"
  context    = module.this.context
  attributes = ["web-${random_id.s3_suffix.dec}"]
}

resource "aws_s3_bucket_policy" "default" {
  bucket = module.web_files_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Allow S3 VPCE"
        Effect = "ALLOW"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          module.web_files_bucket.bucket_arn,
          "${module.web_files_bucket.bucket_arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.app_storage_s3_endpoint.id
          }
        }
      }
    ]
  })
}
