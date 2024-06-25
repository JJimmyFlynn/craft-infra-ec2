resource "aws_db_subnet_group" "default" {
  name       = module.this.id
  subnet_ids = aws_subnet.private.*.id

  tags = module.this.tags
}

resource "aws_rds_cluster" "default" {
  engine                      = "aurora-mysql"
  engine_version              = "8.0"
  engine_mode                 = "provisioned"
  manage_master_user_password = true
  master_username             = "admin"
  db_subnet_group_name        = aws_db_subnet_group.default.name
  skip_final_snapshot = true


  tags = module.this.tags

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }
}

resource "aws_rds_cluster_instance" "default" {
  count                = var.aurora_instance_count
  cluster_identifier   = aws_rds_cluster.default.id
  engine               = aws_rds_cluster.default.engine
  engine_version       = aws_rds_cluster.default.engine_version
  instance_class       = "db.serverless"
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.default.name

  tags = module.this.tags
}
