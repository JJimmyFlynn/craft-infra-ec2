resource "aws_ssm_parameter" "env_db_server" {
  name       = "/example-application/${module.this.stage}/CRAFT_DB_SERVER"
  type       = "String"
  value      = aws_rds_cluster.default.endpoint
  depends_on = [aws_rds_cluster.default]
}

resource "aws_ssm_parameter" "env_db_database" {
  name       = "/example-application/${module.this.stage}/CRAFT_DB_DATABASE"
  type       = "String"
  value      = aws_rds_cluster.default.database_name
  depends_on = [aws_rds_cluster.default]
}

// In a multi-node redis cluster this would need to be more robust to handle
// Craft's "replicas" parameter in its redis config
resource "aws_ssm_parameter" "env_redis_endpoint" {
  name  = "/example-application/${module.this.stage}/CRAFT_REDIS_ENDPOINT"
  type  = "String"
  value = aws_elasticache_cluster.default.cache_nodes[0].address
}

resource "aws_ssm_parameter" "env_s3_bucket" {
  name  = "/example-application/${module.this.stage}/CRAFT_S3_BUCKET"
  type  = "String"
  value = module.web_files_bucket.bucket
}

resource "aws_ssm_parameter" "env_s3_region" {
  name  = "/example-application/${module.this.stage}/CRAFT_S3_REGION"
  type  = "String"
  value = module.web_files_bucket.bucket_region
}

resource "aws_ssm_parameter" "env_s3_base_url" {
  name  = "/example-application/${module.this.stage}/CRAFT_ASSET_BASE_URL"
  type  = "String"
  value = "https://${aws_cloudfront_distribution.craft_europa.domain_name}"
}

resource "aws_ssm_parameter" "env_cloudfront_id" {
  name  = "/example-application/${module.this.stage}/CRAFT_CLOUDFRONT_ID"
  type  = "String"
  value = aws_cloudfront_distribution.craft_europa.id
}
