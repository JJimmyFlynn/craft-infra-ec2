variable "az_count" {
  type        = number
  description = "The number of NAT gateways to provision. This should be equivalent to the total number of AZs used by your application"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of the IDs of subnets into which a NAT gateway will be provisioned"
}

variable "internet_gateway_id" {
  type        = string
  description = "The Internet Gateway ID for the VPC. Used to create a dependency for the NAT Gateway creation"
}
