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

/*=========== Policy Document Definitions ===========*/
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "get_sss_parameters_by_path" {
  statement {
    sid     = "AllowAccessToEnvironmentParameters"
    actions = ["ssm:GetParametersByPath"]
    effect  = "Allow"

    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.parameter_store_path}"]
  }
}

data "aws_iam_policy_document" "app_s3_access" {
  statement {
    sid     = "AllowAppAccessToS3"
    effect  = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      module.web_files_bucket.bucket_arn,
      "${module.web_files_bucket.bucket_arn}/*"
    ]
  }
}

/*=========== Policy Definitions ===========*/
resource "aws_iam_policy" "allow_get_ssm_env_params" {
  name   = "GetSSMEnvironmentParams"
  policy = data.aws_iam_policy_document.get_sss_parameters_by_path.json
}

resource "aws_iam_policy" "allow_web_files_s3_access" {
  name   = "AllowWebFilesS3Access"
  policy = data.aws_iam_policy_document.app_s3_access.json
}

/*=========== Role Definitions ===========*/
resource "aws_iam_role" "webserver_instance_role" {
  name               = "${module.ec2_instance_role_label.id}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json

  tags = module.ec2_instance_role_label.tags
}

/*=========== Role Policy Attachment Definitions ===========*/
resource "aws_iam_role_policy_attachment" "ec2_instance_role_base" {
  policy_arn = data.aws_iam_policy.managed_ssm_policy.arn
  role       = aws_iam_role.webserver_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_get_params" {
  policy_arn = aws_iam_policy.allow_get_ssm_env_params.arn
  role       = aws_iam_role.webserver_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_allow_s3" {
  policy_arn = aws_iam_policy.allow_web_files_s3_access.arn
  role       = aws_iam_role.webserver_instance_role.name
}

/*=========== Instance Profile Definitions ===========*/
resource "aws_iam_instance_profile" "webserver_instance_profile" {
  name = module.this.id
  role = aws_iam_role.webserver_instance_role.name
}
