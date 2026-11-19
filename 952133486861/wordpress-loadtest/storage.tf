resource "aws_s3_bucket" "canaryArtifacts" {
  bucket              = "canaryartifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "canaryArtifacts"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "canaryArtifacts_lifecycle" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    expiration {
      days                         = 15
      expired_object_delete_marker = false
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "canaryArtifacts_controls" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "canaryArtifacts_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.canaryArtifacts.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "canaryArtifacts_configuration" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "canaryArtifacts_versioning" {
  bucket = aws_s3_bucket.canaryArtifacts.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}
