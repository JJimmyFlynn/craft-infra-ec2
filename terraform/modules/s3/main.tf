resource "aws_s3_bucket" "default" {
  bucket = module.this.id
  tags   = module.this.tags
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  count = var.enable_replication ? 1 : 0

  depends_on = [aws_s3_bucket_versioning.default]

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.default.id

  dynamic "rule" {
    for_each = var.destination_bucket_arns
    content {
      id = "relication-${rule.key}"

      delete_marker_replication {
        status = "Disabled"
      }

      filter {
        prefix = ""
      }

      status = "Enabled"

      destination {
        bucket        = rule.value
        storage_class = "STANDARD"
      }
    }
  }
}
