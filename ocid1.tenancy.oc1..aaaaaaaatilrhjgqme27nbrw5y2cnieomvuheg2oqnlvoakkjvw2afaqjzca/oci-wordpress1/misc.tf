resource "terraform_data" "wordpress1_image" {
  input = ["Canonical Ubuntu", "24.04", "arm64"]
}
