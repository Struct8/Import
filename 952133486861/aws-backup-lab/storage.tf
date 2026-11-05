resource "aws_s3_bucket" "backup-lab-docs" {
  bucket              = "backup-lab-docs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    "Struct8:Backup:backup-lab-hourly-8ee55440" = true
    Name                                        = "backup-lab-docs"
    State                                       = "aws-backup-lab"
    Struct8Creator                              = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "backup-lab-docs_controls" {
  bucket = aws_s3_bucket.backup-lab-docs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "backup-lab-docs_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.backup-lab-docs.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup-lab-docs_configuration" {
  bucket = aws_s3_bucket.backup-lab-docs.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "backup-lab-docs_versioning" {
  bucket = aws_s3_bucket.backup-lab-docs.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Enabled"
  }
}

resource "aws_s3_object" "doc-readme" {
  acl          = "private"
  bucket       = aws_s3_bucket.backup-lab-docs.bucket
  content      = "AWS Backup lab. This file was created by Terraform when the lab was applied."
  content_type = "text/plain"
  key          = "docs/readme.txt"
  tags = {
    Name           = "doc-readme"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "doc-report" {
  acl    = "private"
  bucket = aws_s3_bucket.backup-lab-docs.bucket
  content = <<EOF
order_id;customer;total
1001;Ana;129.90
1002;Bruno;54.00
1003;Carla;310.50
  EOF
  content_type = "text/csv"
  key          = "docs/report.csv"
  tags = {
    Name           = "doc-report"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_access_point" "ap_efs-writer_lab-data" {
  file_system_id = aws_efs_file_system.lab-data.id
  posix_user {
    gid = "0"
    uid = "0"
  }
  root_directory {
    path = "/"
  }
  tags = {
    Name           = "ap_efs-writer_lab-data"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_backup_policy" "lab-data_backup_policy" {
  file_system_id = aws_efs_file_system.lab-data.id
  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_file_system" "lab-data" {
  availability_zone_name = "us-west-2a"
  encrypted              = true
  throughput_mode        = "elastic"
  tags = {
    "Struct8:Backup:backup-lab-hourly-8ee55440" = true
    Name                                        = "lab-data"
    State                                       = "aws-backup-lab"
    Struct8Creator                              = "Contato Struct"
  }
}

resource "aws_efs_mount_target" "mt_lab-data_pubA1" {
  file_system_id  = aws_efs_file_system.lab-data.id
  subnet_id       = aws_subnet.pubA1.id
  security_groups = [aws_security_group.efs_file_system_lab-data_group.id]
}

resource "aws_backup_plan" "backup-lab-hourly" {
  name = "backup-lab-hourly"
  rule {
    rule_name         = "hourly"
    target_vault_name = aws_backup_vault.backup-lab-vault.name
    completion_window = 120
    schedule          = "cron(0 * * * ? *)"
    start_window      = 60
    lifecycle {
      delete_after = 1
    }
  }
  tags = {
    Name           = "backup-lab-hourly"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_backup_selection" "backup-lab-hourly_selection" {
  name      = "backup-lab-hourly-8ee55440-resources"
  plan_id   = aws_backup_plan.backup-lab-hourly.id
  resources = ["arn:aws:dynamodb:*:*:table/*", "arn:aws:elasticfilesystem:*:*:file-system/*", "arn:aws:s3:::*"]
  condition {
    string_equals {
      key   = "aws:ResourceTag/Struct8:Backup:backup-lab-hourly-8ee55440"
      value = true
    }
  }
  iam_role_arn = aws_iam_role.role_backup_backup-lab-hourly.arn
}

resource "aws_backup_vault" "backup-lab-vault" {
  name          = "backup-lab-vault"
  force_destroy = true
  tags = {
    Name           = "backup-lab-vault"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}
