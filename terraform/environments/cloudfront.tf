resource "aws_cloudfront_origin_access_control" "web_s3" {
  name                              = module.this.id
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "default" {
  comment = "Example Application - Front ALB"
  enabled = true
  aliases = [var.domain]
  web_acl_id = aws_wafv2_web_acl.managed_rules.arn
  price_class = "PriceClass_100" // NA & EU

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.default.arn
    ssl_support_method = "sni-only"
  }

  // ALB origin
  origin {
    domain_name              = aws_alb.default.dns_name
    origin_id                = aws_alb.default.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  // Web files S3 bucket origin
  origin {
    domain_name = module.web_files_bucket.bucket_domain_name
    origin_id   = module.web_files_bucket.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.web_s3.id
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_alb.default.dns_name
    cache_policy_id        = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" // AWS Managed - UseOriginCacheControlHeaders-QueryStrings
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" // AWS Managed - AllViewer
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    path_pattern           = "/assets/*"
    target_origin_id       = module.web_files_bucket.bucket_domain_name
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" // AWS Managed - CachingOptimized
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
}
