resource "aws_s3_bucket" "module-runner-files" {
  bucket              = "module-runner-files-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "module-runner-files"
    State          = "runner-files"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "module-runner-files_controls" {
  bucket = aws_s3_bucket.module-runner-files.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "module-runner-files_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.module-runner-files.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "module-runner-files_configuration" {
  bucket = aws_s3_bucket.module-runner-files.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "module-runner-files_versioning" {
  bucket = aws_s3_bucket.module-runner-files.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}
