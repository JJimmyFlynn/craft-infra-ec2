# Fetch AZs in the current region
data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

# Cloudfront prefix list
data "aws_ec2_managed_prefix_list" "cloudfront_prefix_list" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
# ec2.johnjflynn.net ACM certificate
data "aws_acm_certificate" "default" {
  domain   = var.domain
  statuses = ["ISSUED"]
}
