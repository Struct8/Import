resource "aws_iam_instance_profile" "beanstalk-uptime-kuma_profile" {
  name = "beanstalk-uptime-kuma_profile"
  role = aws_iam_role.beanstalk-uptime-kuma_role.name
  tags = {
    Name           = "beanstalk-uptime-kuma_profile"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "beanstalk-wordpress-web_profile" {
  name = "beanstalk-wordpress-web_profile"
  role = aws_iam_role.beanstalk-wordpress-web_role.name
  tags = {
    Name           = "beanstalk-wordpress-web_profile"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "elastic_beanstalk_environment_beanstalk-uptime-kuma_st_beanstalk-wordpress_doc" {
  statement {
    sid       = "AllowRDSSecretAccesswpebdb"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.wp-eb-db.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowPullFromRepository"
    effect    = "Allow"
    actions   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [aws_ecr_repository.kuma-image.arn]
  }
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
    resources = ["${aws_efs_file_system.wp-eb-files.arn}:*"]
  }
  statement {
    sid       = "BeanstalkSourceBundle"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.beanstalk-wordpress-versions.arn}/beanstalk/beanstalk-uptime-kuma/*"]
  }
  statement {
    sid       = "AllowEcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "elastic_beanstalk_environment_beanstalk-uptime-kuma_st_beanstalk-wordpress" {
  name        = "elastic_beanstalk_environment_beanstalk-uptime-kuma_st_beanstalk-wordpress"
  description = "Access Policy for beanstalk-uptime-kuma"
  policy      = data.aws_iam_policy_document.elastic_beanstalk_environment_beanstalk-uptime-kuma_st_beanstalk-wordpress_doc.json
}

data "aws_iam_policy_document" "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress_doc" {
  statement {
    sid       = "AllowRDSSecretAccesswpebdb"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.wp-eb-db.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowPullFromRepository"
    effect    = "Allow"
    actions   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
    resources = [aws_ecr_repository.wp-image.arn]
  }
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
    resources = ["${aws_efs_file_system.wp-eb-files.arn}:*"]
  }
  statement {
    sid       = "BeanstalkSourceBundle"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.beanstalk-wordpress-versions.arn}/beanstalk/beanstalk-wordpress-web/*"]
  }
  statement {
    sid       = "AllowReadParam"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.ebWpAdminPassword.arn]
  }
  statement {
    sid       = "AllowSecureStringDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = ["ssm.*.amazonaws.com"]
      variable = "kms:ViaService"
    }
  }
  statement {
    sid       = "AllowEcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress" {
  name        = "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress"
  description = "Access Policy for beanstalk-wordpress-web"
  policy      = data.aws_iam_policy_document.elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress_doc.json
}

resource "aws_iam_role" "beanstalk-uptime-kuma_role" {
  name = "beanstalk-uptime-kuma_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "beanstalk-uptime-kuma_role"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "beanstalk-wordpress-web_role" {
  name = "beanstalk-wordpress-web_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "beanstalk-wordpress-web_role"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkMulticontainerDocker_to_beanstalk-uptime-kuma_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  role       = aws_iam_role.beanstalk-uptime-kuma_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkMulticontainerDocker_to_beanstalk-wordpress-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWebTier_to_beanstalk-uptime-kuma_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.beanstalk-uptime-kuma_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWebTier_to_beanstalk-wordpress-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWorkerTier_to_beanstalk-uptime-kuma_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.beanstalk-uptime-kuma_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWorkerTier_to_beanstalk-wordpress-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_environment_beanstalk-uptime-kuma_st_beanstalk-wordpress_attach" {
  policy_arn = aws_iam_policy.elastic_beanstalk_environment_beanstalk-uptime-kuma_st_beanstalk-wordpress.arn
  role       = aws_iam_role.beanstalk-uptime-kuma_role.name
}

resource "aws_iam_role_policy_attachment" "elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress_attach" {
  policy_arn = aws_iam_policy.elastic_beanstalk_environment_beanstalk-wordpress-web_st_beanstalk-wordpress.arn
  role       = aws_iam_role.beanstalk-wordpress-web_role.name
}
