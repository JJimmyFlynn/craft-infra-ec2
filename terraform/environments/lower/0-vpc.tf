locals {
  az_count = var.vpc_az_count
}

# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

/****************************************
* Base VPC
*****************************************/
resource "aws_vpc" "default" {
  enable_dns_hostnames = true
  cidr_block           = "10.10.0.0/16"
  tags                 = module.this.tags
}

/****************************************
* Subnets
*****************************************/
module "private_subnet_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["private"]

  context = module.this.context
}

resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, local.az_count, count.index)
  tags              = module.private_subnet_label.tags
}

module "public_subnet_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["public"]

  context = module.this.context
}

resource "aws_subnet" "public" {
  count             = local.az_count
  vpc_id            = aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, local.az_count, count.index + local.az_count) // pickup where private subnet creation left off
  tags              = module.public_subnet_label.tags
}

/****************************************
* Internet Gateway
*****************************************/
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

/****************************************
* NAT Gateway
* Optional - Include this module if private EC2
* instances need outbound web access
*****************************************/
module "nat_gateways" {
  source              = "../../modules/nat-gateway"
  az_count            = local.az_count
  subnet_ids          = aws_subnet.public.*.id
  internet_gateway_id = aws_internet_gateway.default.id
}

/****************************************
* Route Tables
*****************************************/
// PUBLIC WEB ACCESS
resource "aws_route_table" "web_access" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = module.this.tags
}

resource "aws_route_table_association" "web_access" {
  count          = local.az_count
  route_table_id = aws_route_table.web_access.id
  subnet_id      = aws_subnet.public.*.id[count.index]
}

// OUTBOUND ONLY WEB ACCESS
resource "aws_route_table" "outbound_web_access" {
  count  = local.az_count
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = module.nat_gateways.nat_gateways.*.id[count.index]
  }

  tags = module.this.tags
}

resource "aws_route_table_association" "private_web_access" {
  count          = local.az_count
  route_table_id = aws_route_table.outbound_web_access.*.id[count.index]
  subnet_id      = aws_subnet.private.*.id[count.index]
}


/****************************************
* Cloudwatch VPC Interface Endpoint
*****************************************/
module "cloudwatch_endpoint_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["cloudwatch"]

  context = module.this.context
}

resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_id              = aws_vpc.default.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = module.cloudwatch_endpoint_label.tags
}

/****************************************
* S3 Gateway Endpoint
*****************************************/
module "s3_endpoint_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["s3"]

  context = module.this.context
}

resource "aws_vpc_endpoint" "app_storage_s3_endpoint" {
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.default.id
  auto_accept       = true
  route_table_ids   = aws_route_table.outbound_web_access.*.id
  tags              = module.s3_endpoint_label.tags
}

/****************************************
* SSM Interface Endpoint
*****************************************/
module "ssm_endpoint_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["ssm"]

  context = module.this.context
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  service_name        = "com.amazonaws.us-east-1.ssm"
  vpc_id              = aws_vpc.default.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = module.s3_endpoint_label.tags
}

/****************************************
* SSM Messages Interface Endpoint
*****************************************/
module "ssm_messages_endpoint_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["ssm-messages"]

  context = module.this.context
}

resource "aws_vpc_endpoint" "ssm_messages_endpoint" {
  service_name        = "com.amazonaws.us-east-1.ssmmessages"
  vpc_id              = aws_vpc.default.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = module.ssm_messages_endpoint_label.tags
}
