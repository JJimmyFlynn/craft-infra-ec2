/****************************************
* Load Balancer
*****************************************/
resource "aws_alb" "default" {
  name               = module.this.id
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.load_balancer.id]
  tags               = module.this.tags
}

module "frontend_target_group_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["frontend"]

  tags = {
    tier = "frontend"
  }

  context = module.this.context
}

resource "aws_alb_target_group" "default" {
  name     = module.frontend_target_group_label.name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
  tags     = module.frontend_target_group_label.tags

  health_check {
    healthy_threshold = 3
    interval = 15
    path = "/actions/app/health-check"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "web_traffic_http" {
  load_balancer_arn = aws_alb.default.arn
  port              = 80

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "web_traffic_https" {
  load_balancer_arn = aws_alb.default.arn
  protocol          = "HTTPS"
  port              = 443
  certificate_arn   = data.aws_acm_certificate.default.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }
}
