/****************************************
* EC2 Instance Profile
*****************************************/
module "ec2_instance_role_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.this.context
}

data "aws_iam_policy" "managed_ssm_policy" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webserver_instance_role" {
  name = "${module.ec2_instance_role_label.id}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json

  tags = module.ec2_instance_role_label.tags
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role" {
  policy_arn  = data.aws_iam_policy.managed_ssm_policy.arn
  role        = aws_iam_role.webserver_instance_role.name
}

resource "aws_iam_instance_profile" "webserver_instance_profile" {
  name = module.this.id
  role = aws_iam_role.webserver_instance_role.name
}
