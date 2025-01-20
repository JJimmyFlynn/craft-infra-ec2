variable "role_arn" {
  type = string
  description = "ARN of the role for terraform to assume"
}

variable "domain" {
  type = string
  description = "Domain name of the application and ACM cert"
}

variable "vpc_az_count" {
  type        = number
  default     = 2
  description = "The number of private and public subnets to be created. Each will be provisioned into their own AZ"
}

variable "aurora_min_capacity" {
  type        = number
  default     = 1
  description = "The minimum ACUs used in the RDS autoscaling policy. Must be less than `aurora_min_capacity`. Range of 0.5 - 128"
}

variable "aurora_max_capacity" {
  type        = number
  default     = 4
  description = "The maximum ACUs used in the RDS autoscaling policy. Must be more than `aurora_min_capacity`. Range of 1 - 128"
}

variable "aurora_instance_count" {
  type        = number
  default     = 1
  description = "The total number of instances to create in the RDS cluster"
}

variable "redis_node_type" {
  type    = string
  default = "cache.r7g.large"
}

variable "redis_instance_count" {
  type    = number
  default = 1
}

variable "autoscaling_min_quantity" {
  type = number
  default = 1
  description = "Minimum ec2 instances for the autoscaling group"
}

variable "autoscaling_max_quantity" {
  type = number
  default = 3
  description = "Maximum ec2 instances for the autoscaling group"
}

variable "autoscaling_cpu_tracking_target" {
  type = number
  default = 60
  description = "The target average CPU usage of the autoscaling group used in the target tracking autoscaling policy"
}
