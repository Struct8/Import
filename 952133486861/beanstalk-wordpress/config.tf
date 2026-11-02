resource "aws_ssm_parameter" "ebWpAdminPassword" {
  name        = "ebWpAdminPassword"
  data_type   = "text"
  description = "Password of the WordPress administrator created by the first start of the site. Terraform generates it."
  overwrite   = false
  tier        = "Standard"
  type        = "SecureString"
  value       = random_password.ebWpAdminPassword.result
  lifecycle {
    ignore_changes = [value]
  }
  tags = {
    Name           = "ebWpAdminPassword"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}
