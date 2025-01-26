resource "aws_ssm_parameter" "env_db_server" {
  name = "/example-application/${module.this.stage}/CRAFT_DB_SERVER"
  type = "String"
  value = aws_rds_cluster.default.endpoint
  depends_on = [aws_rds_cluster.default]
}

resource "aws_ssm_parameter" "env_db_database" {
  name = "/example-application/${module.this.stage}/CRAFT_DB_DATABASE"
  type = "String"
  value = aws_rds_cluster.default.database_name
  depends_on = [aws_rds_cluster.default]
}
