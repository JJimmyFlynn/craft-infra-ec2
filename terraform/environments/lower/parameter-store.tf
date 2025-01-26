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

// In a multi-node redis cluster this would need to be more robust to handle
// Craft's "replicas" parameter in its redis config
resource "aws_ssm_parameter" "env_redis_endpoint" {
  name = "/example-application/${module.this.stage}/CRAFT_REDIS_ENDPOINT"
  type = "String"
  value = aws_elasticache_cluster.default.cache_nodes[0].address
}
