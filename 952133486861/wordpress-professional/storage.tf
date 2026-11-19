resource "aws_s3_bucket" "albLogs" {
  bucket              = "wp-pro-access-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "albLogs"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "wpMedia" {
  bucket              = "wp-pro-media-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    "Struct8:Backup:wpDailyBackup-uZbC08JN" = true
    Name                                    = "wpMedia"
    State                                   = "wordpress-professional"
    Struct8Creator                          = "Contato Struct"
  }
}

resource "aws_s3_bucket" "wpSetupFiles" {
  bucket              = "wp-pro-setup-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "wpSetupFiles"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "albLogs_lifecycle" {
  bucket = aws_s3_bucket.albLogs.id
  rule {
    id     = "expire-alb-logs-7d"
    status = "Enabled"
    expiration {
      days                         = 7
      expired_object_delete_marker = false
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "albLogs_controls" {
  bucket = aws_s3_bucket.albLogs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "wpMedia_controls" {
  bucket = aws_s3_bucket.wpMedia.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "wpSetupFiles_controls" {
  bucket = aws_s3_bucket.wpSetupFiles.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_albLogs_st_wordpress-professional_doc" {
  statement {
    sid    = "AllowElbAccessLogs"
    effect = "Allow"
    principals {
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.albLogs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:elasticloadbalancing:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/*"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_albLogs_st_wordpress-professional" {
  bucket = aws_s3_bucket.albLogs.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_albLogs_st_wordpress-professional_doc.json
}

data "aws_iam_policy_document" "aws_s3_bucket_policy_wpMedia_st_wordpress-professional_doc" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.wpMedia.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdnWordpress.id}"]
    }
  }
}

resource "aws_s3_bucket_policy" "aws_s3_bucket_policy_wpMedia_st_wordpress-professional" {
  bucket = aws_s3_bucket.wpMedia.id
  policy = data.aws_iam_policy_document.aws_s3_bucket_policy_wpMedia_st_wordpress-professional_doc.json
}

resource "aws_s3_bucket_public_access_block" "albLogs_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.albLogs.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "wpMedia_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.wpMedia.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "wpSetupFiles_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.wpSetupFiles.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "albLogs_configuration" {
  bucket = aws_s3_bucket.albLogs.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wpMedia_configuration" {
  bucket = aws_s3_bucket.wpMedia.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_key.kmsWordpress.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wpSetupFiles_configuration" {
  bucket = aws_s3_bucket.wpSetupFiles.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "albLogs_versioning" {
  bucket = aws_s3_bucket.albLogs.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "wpMedia_versioning" {
  bucket = aws_s3_bucket.wpMedia.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "wpSetupFiles_versioning" {
  bucket = aws_s3_bucket.wpSetupFiles.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "wpSetupScript" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/container/wp-auto-setup.sh"
  bucket       = aws_s3_bucket.wpSetupFiles.bucket
  content_type = "text/x-shellscript"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/container/wp-auto-setup.sh")
  key          = "wordpress/wp-auto-setup.sh"
  tags = {
    Name           = "wpSetupScript"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_access_point" "ap_wordpress_wpContent" {
  file_system_id = aws_efs_file_system.wpContent.id
  posix_user {
    gid = "33"
    uid = "33"
  }
  root_directory {
    path = "/wordpress"
    creation_info {
      owner_gid   = "33"
      owner_uid   = "33"
      permissions = "0755"
    }
  }
  tags = {
    Name           = "ap_wordpress_wpContent"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_file_system" "wpContent" {
  kms_key_id      = data.aws_kms_key.kmsWordpress.arn
  encrypted       = true
  throughput_mode = "elastic"
  tags = {
    "Struct8:Backup:wpDailyBackup-uZbC08JN" = true
    Name                                    = "wpContent"
    State                                   = "wordpress-professional"
    Struct8Creator                          = "Contato Struct"
  }
}

resource "aws_efs_mount_target" "mt_wpContent_dataA" {
  file_system_id  = aws_efs_file_system.wpContent.id
  subnet_id       = aws_subnet.dataA.id
  security_groups = [aws_security_group.efs_file_system_wpContent_group.id]
}

resource "aws_efs_mount_target" "mt_wpContent_dataB" {
  file_system_id  = aws_efs_file_system.wpContent.id
  subnet_id       = aws_subnet.dataB.id
  security_groups = [aws_security_group.efs_file_system_wpContent_group.id]
}
