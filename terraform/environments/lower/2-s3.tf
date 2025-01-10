resource "random_id" "s3_suffix" {
  byte_length = 8
}

/****************************************
* Web Assets Bucket
*****************************************/
module "web_files_bucket" {
  source     = "../../modules/s3"
  context    = module.this.context
  attributes = ["web-${random_id.s3_suffix.dec}"]
}

resource "aws_s3_bucket_policy" "web_assets" {
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

/****************************************
* Application Artifact Bucket
*****************************************/
module "artifact_bucket" {
  source     = "../../modules/s3"
  context    = module.this.context
  attributes = ["artifact-${random_id.s3_suffix.dec}"]
}

resource "aws_s3_bucket_policy" "artifact" {
  bucket = module.artifact_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Allow S3 VPCE"
        Effect = "ALLOW"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          module.artifact_bucket.bucket_arn,
          "${module.artifact_bucket.bucket_arn}/*"
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
