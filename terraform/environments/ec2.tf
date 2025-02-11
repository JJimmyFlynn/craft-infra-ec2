// AMI source for webserver
data "aws_ami" "web" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["fly-php-webserver*"]
  }
}

/****************************************
* EC2 Launch Template
*****************************************/
module "web_server_launch_template" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["webserver"]

  tags = {
    role = "webserver"
    tier = "frontend"
  }

  context = module.this.context
}

resource "aws_launch_template" "web" {
  name                   = module.this.id
  image_id               = data.aws_ami.web.id
  instance_type          = "t3.micro"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.webserver.id]
  user_data = base64encode(templatefile("../scripts/ec2-init.sh", {
    bucket_uri = module.artifact_bucket.bucket,
    site_domain = var.domain,
    parameter_store_path = var.parameter_store_path
  }))

  tag_specifications {
    resource_type = "instance"

    tags = module.web_server_launch_template.tags
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.webserver_instance_profile.arn
  }

  monitoring {
    enabled = true
  }
}

/****************************************
* Autoscaling Group
*****************************************/
resource "aws_autoscaling_group" "web" {
  name                = "${module.this.id}-web"
  min_size            = var.autoscaling_min_quantity
  max_size            = var.autoscaling_max_quantity
  health_check_type   = "ELB"
  vpc_zone_identifier = aws_subnet.private.*.id
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  depends_on = [aws_rds_cluster.default, aws_elasticache_cluster.default]
}

resource "aws_autoscaling_attachment" "default" {
  autoscaling_group_name = aws_autoscaling_group.web.id
  lb_target_group_arn    = aws_alb_target_group.default.arn
}

/****************************************
* Autoscaling Policy
*****************************************/
resource "aws_autoscaling_policy" "cpu_tracking" {
  autoscaling_group_name = aws_autoscaling_group.web.name
  name                   = "${module.this.id}-cpu-tracking"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = var.autoscaling_cpu_tracking_target

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}
