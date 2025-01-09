data "aws_ami" "web" {
  owners = ["self"]
  most_recent = true

  filter {
    name = "name"
    values = ["fly-php-webserver*"]
  }
}

resource "aws_launch_template" "web" {
  name                   = module.this.id
  image_id               = data.aws_ami.web.id
  instance_type          = "t3.micro"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.webserver.id]
  user_data = base64encode(file("../../scripts/ec2-init.sh"))

  iam_instance_profile {
    arn = aws_iam_instance_profile.webserver_instance_profile.arn
  }

  monitoring {
    enabled = true
  }
}

resource aws_autoscaling_group "web" {
  name             = "${module.this.id}-web"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  vpc_zone_identifier = aws_subnet.private.*.id
  launch_template {
    id = aws_launch_template.web.id
    version = "$Latest"
  }
}

resource aws_autoscaling_attachment "default" {
  autoscaling_group_name = aws_autoscaling_group.web.id
  lb_target_group_arn = aws_alb_target_group.default.arn
}
