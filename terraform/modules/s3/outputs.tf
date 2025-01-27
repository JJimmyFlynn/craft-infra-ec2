output "bucket" {
  value = aws_s3_bucket.default.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.default.arn
}

output "bucket_region" {
  value = aws_s3_bucket.default.region
}

output "bucket_domain_name" {
  value = aws_s3_bucket.default.bucket_domain_name
}
