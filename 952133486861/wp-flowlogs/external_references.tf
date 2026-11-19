data "aws_vpc" "wordpress-professional" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-professional"]
  }
}
