/***************************************************************
* NOTE: Changing the vpc_id, name, or description of a security group will
*       force a recreation of that resource.
****************************************************************/

/****************************************
* Web DMZ
*****************************************/
module "web_dmz_sg_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "web-dmz"

  context = module.this.context
}

resource "aws_security_group" "web_dmz" {
  vpc_id      = aws_vpc.default.id
  name        = module.web_dmz_sg_label.id
  tags        = module.web_dmz_sg_label.tags
  description = "Allow external web traffic on http(s)"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_dmz_allow_http" {
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.web_dmz.id
}

resource "aws_vpc_security_group_ingress_rule" "web_dmz_allow_https" {
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.web_dmz.id
}

/****************************************
* Load Balancer
*****************************************/
module "load_balancer_sg_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "load_balancer"

  context = module.this.context
}

resource "aws_security_group" "load_balancer" {
  vpc_id      = aws_vpc.default.id
  name        = module.load_balancer_sg_label.id
  tags        = module.load_balancer_sg_label.tags
  description = "Allow http(s) inbound traffic to load balancer and outbound traffic to webserver SG"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_allow_http" {
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.load_balancer.id
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_allow_https" {
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.load_balancer.id
}

resource "aws_vpc_security_group_egress_rule" "load_balancer_allow_https" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.webserver.id
  security_group_id            = aws_security_group.load_balancer.id
}

resource "aws_vpc_security_group_egress_rule" "load_balancer_allow_http" {
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.webserver.id
  security_group_id            = aws_security_group.load_balancer.id
}

/****************************************
* Webserver
*****************************************/
module "webserver_sg_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "webserver"

  context = module.this.context
}

resource "aws_security_group" "webserver" {
  vpc_id      = aws_vpc.default.id
  name        = module.webserver_sg_label.id
  tags        = module.webserver_sg_label.tags
  description = "Allow inbound http(s) traffic from load balancer SG and allow outbound http(s) to VPC endpoints SG"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "webserver_allow_http" {
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_vpc_security_group_ingress_rule" "webserver_allow_https" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_vpce_http" {
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  description                  = "Allow outbound http traffic to interface vpc endpoints security group"
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_vpce_https" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  description                  = "Allow outbound https traffic to interface vpc endpoints security group"
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_s3_vpce_http" {
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.webserver.id
  prefix_list_id    = aws_vpc_endpoint.app_storage_s3_endpoint.prefix_list_id
  description       = "Allow outbound http traffic to s3 gateway vpc endpoint prefix list"
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_s3_vpce_https" {
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.webserver.id
  prefix_list_id    = aws_vpc_endpoint.app_storage_s3_endpoint.prefix_list_id
  description       = "Allow outbound https traffic to s3 gateway vpc endpoint prefix list"
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_rds" {
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.rds_allow_webserver.id
  description                  = "Allow outbound traffic to RDS SG"
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_redis" {
  from_port                    = 6739
  to_port                      = 6739
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.redis_allow_webserver.id
  description                  = "Allow outbound traffic to redis SG"
}

/****************************************
* VPC Endpoints
*****************************************/
module "vpc_endpoints_sg_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "vpc-endpoints"

  context = module.this.context
}

resource "aws_security_group" "vpc_endpoints" {
  vpc_id      = aws_vpc.default.id
  name        = module.vpc_endpoints_sg_label.id
  tags        = module.vpc_endpoints_sg_label.tags
  description = "Allow inbound http(s) traffic from webserver SG"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_allow_http" {
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.webserver.id
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_allow_https" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.webserver.id
}

/****************************************
* RDS
*****************************************/
module "rds_sg_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "rds-allow-webserver"

  context = module.this.context
}

resource "aws_security_group" "rds_allow_webserver" {
  vpc_id      = aws_vpc.default.id
  name        = module.rds_sg_label.id
  tags        = module.rds_sg_label.tags
  description = "Allow inbound traffic from webserver SG"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_allow_webserver" {
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.rds_allow_webserver.id
  referenced_security_group_id = aws_security_group.webserver.id
}

/****************************************
* Redis
*****************************************/
module "redis_sg_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "redis-allow-webserver"

  context = module.this.context
}

resource "aws_security_group" "redis_allow_webserver" {
  vpc_id      = aws_vpc.default.id
  name        = module.redis_sg_label.id
  tags        = module.redis_sg_label.tags
  description = "Allow inbound access to redis from webserver SG"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_allow_webserver" {
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.redis_allow_webserver.id
  referenced_security_group_id = aws_security_group.webserver.id
}
