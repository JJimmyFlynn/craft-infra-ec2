resource "aws_cloudfront_origin_access_control" "default" {
  name                              = module.this.id
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "craft_europa" {
  enabled = true
  origin {
    domain_name              = module.web_files_bucket.bucket_domain_name
    origin_id                = module.web_files_bucket.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = module.web_files_bucket.bucket
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" // AWS Managed Cache Policy
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_100" // NA & EU

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
}
