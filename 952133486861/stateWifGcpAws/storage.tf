resource "aws_s3_bucket" "wif-gcp-lab-proof" {
  bucket              = "wif-gcp-lab-proof-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "wif-gcp-lab-proof"
    State          = "stateWifGcpAws"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "wif-gcp-lab-proof_controls" {
  bucket = aws_s3_bucket.wif-gcp-lab-proof.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "wif-gcp-lab-proof_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.wif-gcp-lab-proof.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wif-gcp-lab-proof_configuration" {
  bucket = aws_s3_bucket.wif-gcp-lab-proof.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "wif-gcp-lab-proof_versioning" {
  bucket = aws_s3_bucket.wif-gcp-lab-proof.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}
