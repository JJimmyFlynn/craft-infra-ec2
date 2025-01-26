/****************************************
* Aurora Serverless RDS
*****************************************/
data "aws_ssm_parameter" "rds_password" {
  name = "/example-application/dev/CRAFT_DB_PASSWORD"
}

resource "aws_db_subnet_group" "default" {
  name       = module.this.id
  subnet_ids = aws_subnet.private.*.id

  tags = module.this.tags
}

resource "aws_rds_cluster" "default" {
  cluster_identifier          = module.this.id
  engine                      = "aurora-mysql"
  engine_version              = "8.0"
  engine_mode                 = "provisioned"
  master_username             = "admin"
  master_password             = data.aws_ssm_parameter.rds_password.value
  database_name =             "craft"
  db_subnet_group_name        = aws_db_subnet_group.default.name
  skip_final_snapshot         = true
  vpc_security_group_ids = [aws_security_group.rds_allow_webserver.id]

  tags = module.this.tags

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }
}

resource "aws_rds_cluster_instance" "default" {
  identifier           = "${module.this.name}-writer"
  count                = var.aurora_instance_count
  cluster_identifier   = aws_rds_cluster.default.id
  engine               = aws_rds_cluster.default.engine
  engine_version       = aws_rds_cluster.default.engine_version
  instance_class       = "db.serverless"
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.default.name

  tags = module.this.tags
}
