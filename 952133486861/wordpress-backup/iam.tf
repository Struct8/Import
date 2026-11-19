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
  deletion_window_in_days            = 7
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
