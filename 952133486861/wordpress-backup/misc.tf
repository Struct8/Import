resource "random_password" "wpAdminPassword" {
  length  = 16
  special = true
}

resource "random_password" "wpDbPassword" {
  length  = 16
  special = true
}
