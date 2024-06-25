module "web_files_bucket" {
  source     = "../../modules/s3"
  context    = module.this.context
  attributes = ["web-df789sd"]
}
