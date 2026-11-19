data "aws_vpc" "wordpress-professional" {
  filter {
    name   = "tag:Name"
    values = ["wordpress-professional"]
  }
}

data "aws_route_table" "rt-public-wp" {
  filter {
    name   = "tag:Name"
    values = ["rt-public-wp"]
  }
}
