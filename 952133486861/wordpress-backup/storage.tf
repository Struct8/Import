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
