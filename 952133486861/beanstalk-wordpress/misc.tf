resource "random_password" "ebWpAdminPassword" {
  length  = 16
  special = true
}

resource "terraform_data" "seed_kuma-image" {
  triggers_replace = ["${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/image", "latest", "linux/arm64"]
  lifecycle {
    replace_triggered_by = [aws_ecr_repository.kuma-image]
  }
  depends_on = [aws_ecr_repository.kuma-image]
  provisioner "local-exec" {
    command = <<EOF
set -e
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.kuma-image.repository_url)[0]}
[ "$(uname -m)" = aarch64 ] || [ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || docker run --privileged --rm tonistiigi/binfmt:qemu-v10.2.3@sha256:400a4873b838d1b89194d982c45e5fb3cda4593fbfd7e08a02e76b03b21166f0 --install arm64
docker build --provenance=false --platform linux/arm64 -t ${aws_ecr_repository.kuma-image.repository_url}:latest ${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/image
docker push ${aws_ecr_repository.kuma-image.repository_url}:latest
    EOF
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "terraform_data" "seed_wp-image" {
  triggers_replace = ["${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/image", "latest", "linux/arm64"]
  lifecycle {
    replace_triggered_by = [aws_ecr_repository.wp-image]
  }
  depends_on = [aws_ecr_repository.wp-image]
  provisioner "local-exec" {
    command = <<EOF
set -e
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.wp-image.repository_url)[0]}
[ "$(uname -m)" = aarch64 ] || [ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] || docker run --privileged --rm tonistiigi/binfmt:qemu-v10.2.3@sha256:400a4873b838d1b89194d982c45e5fb3cda4593fbfd7e08a02e76b03b21166f0 --install arm64
docker build --provenance=false --platform linux/arm64 -t ${aws_ecr_repository.wp-image.repository_url}:latest ${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/image
docker push ${aws_ecr_repository.wp-image.repository_url}:latest
    EOF
    interpreter = ["/bin/bash", "-c"]
  }
}
