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
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
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
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
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
  subnet_id      = element(aws_subnet.public.*.id, count.index)
}

// OUTBOUND ONLY WEB ACCESS
resource "aws_route_table" "outbound_web_access" {
  count  = local.az_count
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(module.nat_gateways.nat_gateways.*.id, count.index)
  }

  tags = module.this.tags
}

resource "aws_route_table_association" "private_web_access" {
  count          = local.az_count
  route_table_id = element(aws_route_table.outbound_web_access.*.id, count.index)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
}

/****************************************
* Load Balancer
*****************************************/
resource "aws_alb" "load_balancer" {
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.web_dmz.id]
  tags               = module.this.tags
}

/****************************************
* Cloudwatch VPC Interface Endpoint
*****************************************/
resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  service_name      = "com.amazonaws.us-east-1.logs"
  vpc_id            = aws_vpc.default.id
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

/****************************************
* S3 Gateway Endpoint
*****************************************/
resource "aws_vpc_endpoint" "app_storage_s3_endpoint" {
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.default.id
  auto_accept       = true
  route_table_ids   = aws_route_table.outbound_web_access.*.id
}

/****************************************
* SSM Interface Endpoint
*****************************************/
resource "aws_vpc_endpoint" "ssm_endpoint" {
  service_name      = "com.amazonaws.us-east-1.ssm"
  vpc_id            = aws_vpc.default.id
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

/****************************************
* SSM Messages Interface Endpoint
*****************************************/
resource "aws_vpc_endpoint" "ssm_messages_endpoint" {
  service_name      = "com.amazonaws.us-east-1.ssmmessages"
  vpc_id            = aws_vpc.default.id
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

/****************************************
* SSM Contact Interface Endpoint
*****************************************/
resource "aws_vpc_endpoint" "ssm_contacts_endpoint" {
  service_name      = "com.amazonaws.us-east-1.ssm-contacts"
  vpc_id            = aws_vpc.default.id
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private[0].id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}
