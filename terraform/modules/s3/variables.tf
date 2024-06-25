variable "bucket_name_suffix" {
  type        = string
  default     = ""
  description = "This suffix will be appended to the context generated name of the bucket. E.g. web, logs, etc"
}

variable "enable_versioning" {
  type        = bool
  default     = true
  description = "Whether to enable object versioning on the bucket"
}

variable "enable_replication" {
  type        = bool
  default     = false
  description = "Whether to enable replication from this bucket to another destination bucket. When true also creates required IAM Role and Policies for replication"
}

variable "destination_bucket_arns" {
  type        = list(string)
  default     = []
  description = "If replication is enabled, the destination bucket for objects to be replicated to"
}
