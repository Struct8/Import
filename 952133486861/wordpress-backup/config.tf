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
