namespace   = "flynn"
stage       = "dev"
environment = "ue1"
name        = "example-application"
role_arn = "arn:aws:iam::654654165875:role/TerraformAccess"
tags = {
  "Managed by Terraform" = "True"
  "Created By"           = "Flynndustries"
}
vpc_az_count    = 3
redis_node_type = "cache.t4g.micro"
