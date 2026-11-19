resource "aws_s3_bucket" "cdnLogBucket" {
  bucket              = "cdnlogbucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "cdnLogBucket"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "cdnLogBucket_controls" {
  bucket = aws_s3_bucket.cdnLogBucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cdnLogBucket_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.cdnLogBucket.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cdnLogBucket_configuration" {
  bucket = aws_s3_bucket.cdnLogBucket.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "cdnLogBucket_versioning" {
  bucket = aws_s3_bucket.cdnLogBucket.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}
