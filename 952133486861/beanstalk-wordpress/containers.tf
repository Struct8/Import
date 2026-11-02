resource "aws_ecr_repository" "kuma-image" {
  name                 = "kuma-image"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  tags = {
    Name           = "kuma-image"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecr_repository" "wp-image" {
  name                 = "wp-image"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  tags = {
    Name           = "wp-image"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}
