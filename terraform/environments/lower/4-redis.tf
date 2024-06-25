resource "aws_elasticache_parameter_group" "default" {
  family = "redis7"
  name   = module.this.id

  tags = module.this.tags
}

resource "aws_elasticache_subnet_group" "default" {
  name = module.this.id
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_elasticache_cluster" "default" {
  cluster_id           = module.this.id
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_instance_count
  parameter_group_name = aws_elasticache_parameter_group.default.name
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name = aws_elasticache_subnet_group.default.name

  tags = module.this.tags
}
