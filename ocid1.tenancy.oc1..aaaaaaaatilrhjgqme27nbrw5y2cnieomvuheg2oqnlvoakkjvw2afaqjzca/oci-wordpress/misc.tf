resource "terraform_data" "wordpress_image" {
  input = ["Canonical Ubuntu", "24.04", "x86_64"]
}
