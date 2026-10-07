terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/wordpress-backup/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

resource "aws_iam_role" "wpDailyBackup_backup_role" {
  name = "wpDailyBackup-uZbC08JN-backup"
  assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect    = "Allow"
    Principal = { Service = "backup.amazonaws.com" }
    Action    = "sts:AssumeRole"
  }]
})
  tags = {
    Name           = "wpDailyBackup_backup_role"
    State          = "wordpress-backup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "wpDailyBackup_backup_role_backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.wpDailyBackup_backup_role.name
}

resource "aws_iam_role_policy_attachment" "wpDailyBackup_backup_role_restores" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.wpDailyBackup_backup_role.name
}

resource "aws_iam_role_policy_attachment" "wpDailyBackup_backup_role_s3_backup" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.wpDailyBackup_backup_role.name
}

resource "aws_iam_role_policy_attachment" "wpDailyBackup_backup_role_s3_restore" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.wpDailyBackup_backup_role.name
}

resource "aws_kms_alias" "kmsWordpress_cross_state_alias" {
  name          = "alias/kmsWordpress-xnA-aVKz"
  target_key_id = aws_kms_key.kmsWordpress.key_id
}

resource "aws_kms_key" "kmsWordpress" {
  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = 30
  enable_key_rotation                = true
  is_enabled                         = true
  multi_region                       = false
  rotation_period_in_days            = 365
  tags = {
    Name           = "kmsWordpress"
    State          = "wordpress-backup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_secretsmanager_secret" "wpSecrets" {
  kms_key_id              = aws_kms_key.kmsWordpress.id
  name                    = "wpSecrets"
  description             = "Password of the WordPress database user. Terraform generates it, and each WordPress task creates or updates that user at startup with the Aurora master credentials."
  recovery_window_in_days = 0
  tags = {
    Name           = "wpSecrets"
    State          = "wordpress-backup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_secretsmanager_secret_version" "wpSecrets_version" {
  secret_id     = aws_secretsmanager_secret.wpSecrets.id
  secret_string = random_password.wpDbPassword.result
}




### CATEGORY: STORAGE ###

resource "aws_backup_plan" "wpDailyBackup" {
  name = "wpDailyBackup"
  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.wpBackupVault.name
    completion_window = 180
    schedule          = "cron(0 5 * * ? *)"
    start_window      = 60
    lifecycle {
      delete_after = 35
    }
  }
  tags = {
    Name           = "wpDailyBackup"
    State          = "wordpress-backup"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_backup_selection" "wpDailyBackup_selection" {
  name      = "wpDailyBackup-uZbC08JN-resources"
  plan_id   = aws_backup_plan.wpDailyBackup.id
  resources = ["arn:aws:elasticfilesystem:*:*:file-system/*", "arn:aws:rds:*:*:cluster:*", "arn:aws:s3:::*"]
  condition {
    string_equals {
      key   = "aws:ResourceTag/Struct8:Backup:wpDailyBackup-uZbC08JN"
      value = true
    }
  }
  iam_role_arn = aws_iam_role.wpDailyBackup_backup_role.arn
}

resource "aws_backup_vault" "wpBackupVault" {
  name = "wpBackupVault"
  tags = {
    Name           = "wpBackupVault"
    State          = "wordpress-backup"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_parameter" "wpAdminPassword" {
  key_id      = aws_kms_key.kmsWordpress.arn
  name        = "wpAdminPassword"
  data_type   = "text"
  description = "Password of the WordPress administrator created by the first start of the site. Terraform generates it. Changing it here does not change the password in WordPress after the installation."
  overwrite   = false
  tier        = "Standard"
  type        = "SecureString"
  value       = random_password.wpAdminPassword.result
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    Name           = "wpAdminPassword"
    State          = "wordpress-backup"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "random_password" "wpAdminPassword" {
  length  = 16
  special = true
}

resource "random_password" "wpDbPassword" {
  length  = 16
  special = true
}


