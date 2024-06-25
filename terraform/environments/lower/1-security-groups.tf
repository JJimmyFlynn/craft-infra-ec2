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
  vpc_id = aws_vpc.default.id
  name   = module.web_dmz_sg_label.id
  tags   = module.web_dmz_sg_label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_dmz_allow_http" {
  from_port         = 80
  to_port           = 80
  cidr_ipv4       = "0.0.0.0/0"
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.web_dmz.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_dmz_allow_https" {
  from_port         = 443
  to_port           = 443
  cidr_ipv4       = "0.0.0.0/0"
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.web_dmz.id

  lifecycle {
    create_before_destroy = true
  }
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
  vpc_id = aws_vpc.default.id
  name   = module.load_balancer_sg_label.id
  tags   = module.load_balancer_sg_label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_allow_http" {
  from_port         = 80
  to_port           = 80
  cidr_ipv4       = "0.0.0.0/0"
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.load_balancer.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_allow_https" {
  from_port         = 443
  to_port           = 443
  cidr_ipv4       = "0.0.0.0/0"
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.load_balancer.id

  lifecycle {
    create_before_destroy = true
  }
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
  vpc_id = aws_vpc.default.id
  name   = module.webserver_sg_label.id
  tags   = module.webserver_sg_label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "webserver_allow_http" {
  from_port         = 80
  to_port           = 80
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.load_balancer.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "webserver_allow_https" {
  from_port         = 443
  to_port           = 443
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.load_balancer.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_http" {
  from_port         = 80
  to_port           = 80
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "webserver_allow_outbound_https" {
  from_port         = 443
  to_port           = 443
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.webserver.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id

  lifecycle {
    create_before_destroy = true
  }
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
  vpc_id = aws_vpc.default.id
  name   = module.vpc_endpoints_sg_label.id
  tags   = module.vpc_endpoints_sg_label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_allow_http" {
  from_port         = 80
  to_port           = 80
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.webserver.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_allow_https" {
  from_port         = 443
  to_port           = 443
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.webserver.id

  lifecycle {
    create_before_destroy = true
  }
}