data "aws_ami" "web" {
  owners = ["self"]
  most_recent = true

  filter {
    name = "name"
    values = ["fly-php-webserver*"]
  }
}

resource "aws_launch_template" "web" {
  name = module.this.id
  image_id = data.aws_ami.web.id
  instance_type = "t3.micro"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.webserver.id]

  iam_instance_profile {
    name = "EC2_SSM"
  }

  monitoring {
    enabled = true
  }
}
