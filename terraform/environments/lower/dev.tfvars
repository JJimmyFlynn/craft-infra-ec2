namespace   = "fly"
stage       = "dev"
environment = "ue1"
name        = "example-application"
tags = {
  "Managed by Terraform" = "True"
  "Created By"           = "Flynndustries"
}
vpc_az_count    = 3
redis_node_type = "cache.t4g.micro"
