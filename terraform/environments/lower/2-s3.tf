module "web_files_bucket" {
  source     = "../../modules/s3"
  context    = module.this.context
  attributes = ["web-df789sd"]
}

resource "aws_s3_bucket_policy" "default" {
  bucket = module.web_files_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Restrict to S3 VPCE"
        Effect = "DENY"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          module.web_files_bucket.bucket_arn,
          "${module.web_files_bucket.bucket_arn}/*"
        ]
        Condition = {
          StringNotEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.app_storage_s3_endpoint.id
          }
        }
      }
    ]
  })
}
