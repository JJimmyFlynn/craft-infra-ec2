provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_dns_record" "default" {
  zone_id = var.cloudflare_zone_id
  name = "ec2.johnjflynn.net"
  ttl = 60
  type = "CNAME"
  content = aws_alb.default.dns_name
  proxied = false
}
