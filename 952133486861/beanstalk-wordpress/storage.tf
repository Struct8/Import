resource "aws_s3_bucket" "beanstalk-wordpress-versions" {
  bucket              = "beanstalk-wordpress-versions-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "beanstalk-wordpress-versions"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "beanstalk-wordpress-versions_controls" {
  bucket = aws_s3_bucket.beanstalk-wordpress-versions.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "beanstalk-wordpress-versions_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.beanstalk-wordpress-versions.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "beanstalk-wordpress-versions_configuration" {
  bucket = aws_s3_bucket.beanstalk-wordpress-versions.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "beanstalk-wordpress-versions_versioning" {
  bucket = aws_s3_bucket.beanstalk-wordpress-versions.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "beanstalk-uptime-kuma_bundle" {
  source       = data.archive_file.eb_struct8-templates_beanstalk-uptime-kuma.output_path
  bucket       = aws_s3_bucket.beanstalk-wordpress-versions.id
  content_type = "application/zip"
  etag         = filemd5("${data.archive_file.eb_struct8-templates_beanstalk-uptime-kuma.output_path}")
  key          = "beanstalk/beanstalk-uptime-kuma/${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/app/${f}")}"])), 0, 16)}.zip"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_object" "beanstalk-wordpress-web_bundle" {
  source       = data.archive_file.eb_struct8-templates_beanstalk-wordpress-web.output_path
  bucket       = aws_s3_bucket.beanstalk-wordpress-versions.id
  content_type = "application/zip"
  etag         = filemd5("${data.archive_file.eb_struct8-templates_beanstalk-wordpress-web.output_path}")
  key          = "beanstalk/beanstalk-wordpress-web/${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/app/${f}")}"])), 0, 16)}.zip"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_access_point" "ap_beanstalk-uptime-kuma_wp-eb-files" {
  file_system_id = aws_efs_file_system.wp-eb-files.id
  posix_user {
    gid = 33
    uid = 33
  }
  root_directory {
    path = "/beanstalk-wordpress-blog"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "0755"
    }
  }
  tags = {
    Name           = "ap_beanstalk-uptime-kuma_wp-eb-files"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_access_point" "ap_beanstalk-wordpress-web_wp-eb-files" {
  file_system_id = aws_efs_file_system.wp-eb-files.id
  posix_user {
    gid = 33
    uid = 33
  }
  root_directory {
    path = "/beanstalk-wordpress-web"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "0755"
    }
  }
  tags = {
    Name           = "ap_beanstalk-wordpress-web_wp-eb-files"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_file_system" "wp-eb-files" {
  encrypted       = true
  throughput_mode = "elastic"
  tags = {
    Name           = "wp-eb-files"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_mount_target" "mt_wp-eb-files_wp-data-a" {
  file_system_id  = aws_efs_file_system.wp-eb-files.id
  subnet_id       = aws_subnet.wp-data-a.id
  security_groups = [aws_security_group.efs_file_system_wp-eb-files_group.id]
}

resource "aws_efs_mount_target" "mt_wp-eb-files_wp-data-b" {
  file_system_id  = aws_efs_file_system.wp-eb-files.id
  subnet_id       = aws_subnet.wp-data-b.id
  security_groups = [aws_security_group.efs_file_system_wp-eb-files_group.id]
}
