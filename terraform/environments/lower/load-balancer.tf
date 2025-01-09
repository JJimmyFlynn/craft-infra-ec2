/****************************************
* Load Balancer
*****************************************/
resource "aws_alb" "default" {
  name = module.this.id
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.load_balancer.id]
  tags               = module.this.tags
}

resource aws_alb_target_group "default" {
  name = module.this.id
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.default.id
}

resource "aws_lb_listener" "web_traffic" {
  load_balancer_arn = aws_alb.default.arn
  port = 80

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }
}
