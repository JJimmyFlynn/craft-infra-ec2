/****************************************
* EC2 Instance Profile
*****************************************/
module "ec2_instance_role_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "instance-role"

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

resource "aws_iam_role" "ec2_instance_role" {
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
  managed_policy_arns = [data.aws_iam_policy.managed_ssm_policy.arn]

  tags = module.ec2_instance_role_label.tags
}
