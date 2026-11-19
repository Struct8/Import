resource "aws_iam_instance_profile" "asgWordpress_profile" {
  name = "asgWordpress_profile"
  role = aws_iam_role.asgWordpress_role.name
  tags = {
    Name           = "asgWordpress_profile"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "nat-instance_profile" {
  name = "nat-instance_profile"
  role = aws_iam_role.nat-instance_role.name
  tags = {
    Name           = "nat-instance_profile"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "autoscaling_group_asgWordpress_st_wordpress-professional_doc" {
  statement {
    sid       = "AllowWpcluster"
    effect    = "Allow"
    actions   = ["ecs:DeregisterContainerInstance", "ecs:DiscoverPollEndpoint", "ecs:Poll", "ecs:RegisterContainerInstance", "ecs:StartTelemetrySession", "ecs:Submit*"]
    resources = [aws_ecs_cluster.wp-cluster.arn]
  }
}

resource "aws_iam_policy" "autoscaling_group_asgWordpress_st_wordpress-professional" {
  name        = "autoscaling_group_asgWordpress_st_wordpress-professional"
  description = "Access Policy for asgWordpress"
  policy      = data.aws_iam_policy_document.autoscaling_group_asgWordpress_st_wordpress-professional_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_wordpress_execution_st_wordpress-professional_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logsWordpress.arn}:*"]
  }
  statement {
    sid       = "AllowDecryptInjectedSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.kmsWordpress.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesswpaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowSecretAccess"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.wpSecrets.arn]
  }
  statement {
    sid       = "AllowReadParam"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = [data.aws_ssm_parameter.wpAdminPassword.arn]
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
}

resource "aws_iam_policy" "ecs_task_definition_wordpress_execution_st_wordpress-professional" {
  name        = "ecs_task_definition_wordpress_execution_st_wordpress-professional"
  description = "Access Policy for wordpress (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_wordpress_execution_st_wordpress-professional_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_wordpress_st_wordpress-professional_doc" {
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"]
    resources = [aws_efs_file_system.wpContent.arn]
  }
  statement {
    sid       = "AllowRDSDataApiwpaurora"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.wp-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesswpaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:GetBucketOwnershipControls", "s3:GetBucketPublicAccessBlock", "s3:ListBucket"]
    resources = [aws_s3_bucket.wpMedia.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.wpMedia.arn}/*"]
  }
  statement {
    sid       = "ReadWordPressSetupFiles"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.wpSetupFiles.arn}/wordpress/*"]
  }
  statement {
    sid       = "AllowSesSendFromIdentity"
    effect    = "Allow"
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = [aws_sesv2_email_identity.wpMail.arn]
  }
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:GetSamplingRules", "xray:GetSamplingTargets", "xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_wordpress_st_wordpress-professional" {
  name        = "ecs_task_definition_wordpress_st_wordpress-professional"
  description = "Access Policy for wordpress"
  policy      = data.aws_iam_policy_document.ecs_task_definition_wordpress_st_wordpress-professional_doc.json
}

data "aws_iam_policy_document" "debug-wp_debug_permissions" {
  statement {
    sid       = "RunProbeTaskwordpress"
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["arn:aws:ecs:*:*:task-definition/Struct8Probe-t1eAUxGPRo-vo6lIyc15I-wordpress:*"]
    condition {
      test     = "ArnEquals"
      values   = [aws_ecs_cluster.wp-cluster.arn]
      variable = "ecs:cluster"
    }
  }
  statement {
    sid       = "ReadProbeTaskwordpress"
    effect    = "Allow"
    actions   = ["ecs:DescribeTasks", "ecs:StopTask"]
    resources = ["arn:aws:ecs:*:*:task/*"]
    condition {
      test     = "ArnEquals"
      values   = [aws_ecs_cluster.wp-cluster.arn]
      variable = "ecs:cluster"
    }
  }
  statement {
    sid       = "ReadServiceNetworkwordpress"
    effect    = "Allow"
    actions   = ["ecs:DescribeServices"]
    resources = ["arn:aws:ecs:*:*:service/wp-cluster/wordpress_service"]
    condition {
      test     = "ArnEquals"
      values   = [aws_ecs_cluster.wp-cluster.arn]
      variable = "ecs:cluster"
    }
  }
  statement {
    sid       = "ReadProbeOutputwordpress"
    effect    = "Allow"
    actions   = ["logs:GetLogEvents"]
    resources = ["${aws_cloudwatch_log_group.Struct8Probe_debug-wp_wordpress_logs.arn}:*"]
  }
  statement {
    sid       = "PassProbeExecutionRolewordpress"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.execution_role_ecs_wordpress.arn]
    condition {
      test     = "StringEquals"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }
}

data "aws_iam_policy_document" "debug-wp_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "debug-wp_wordpress_probe_logs" {
  statement {
    sid       = "Struct8ProbeLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.Struct8Probe_debug-wp_wordpress_logs.arn}:*"]
  }
}

resource "aws_iam_role" "Struct8Debug-debug-wp" {
  name                 = "Struct8Debug-t1eAUxGPRo-vo6lIyc15I"
  assume_role_policy   = data.aws_iam_policy_document.debug-wp_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "asgWordpress_role" {
  name = "asgWordpress_role"
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
    Name           = "asgWordpress_role"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_wordpress" {
  name = "execution_role_ecs_wordpress"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "execution_role_ecs_wordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-instance_role" {
  name = "nat-instance_role"
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
    Name           = "nat-instance_role"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_wordpress" {
  name = "task_role_ecs_wordpress"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "task_role_ecs_wordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-debug-wp_policy" {
  name   = "Struct8Debug-t1eAUxGPRo-vo6lIyc15I-policy"
  policy = data.aws_iam_policy_document.debug-wp_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-debug-wp.id
}

resource "aws_iam_role_policy" "Struct8ProbeLogs-debug-wp-wordpress" {
  name   = "Struct8ProbeLogs-t1eAUxGPRo-vo6lIyc15I-wordpress"
  policy = data.aws_iam_policy_document.debug-wp_wordpress_probe_logs.json
  role   = aws_iam_role.execution_role_ecs_wordpress.id
}

resource "aws_iam_role_policy_attachment" "autoscaling_group_asgWordpress_st_wordpress-professional_attach" {
  policy_arn = aws_iam_policy.autoscaling_group_asgWordpress_st_wordpress-professional.arn
  role       = aws_iam_role.asgWordpress_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_wordpress_execution_st_wordpress-professional_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_wordpress_execution_st_wordpress-professional.arn
  role       = aws_iam_role.execution_role_ecs_wordpress.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_wordpress_st_wordpress-professional_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_wordpress_st_wordpress-professional.arn
  role       = aws_iam_role.task_role_ecs_wordpress.name
}

resource "aws_iam_role_policy_attachment" "service_role_AmazonEC2ContainerServiceforEC2Role_to_asgWordpress_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.asgWordpress_role.name
}

resource "aws_acm_certificate" "certAlb" {
  domain_name       = "origin.wp.cloudman.pro"
  key_algorithm     = "RSA_2048"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "certAlb"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate" "certWordpress" {
  domain_name       = "wp.cloudman.pro"
  key_algorithm     = "RSA_2048"
  region            = "us-east-1"
  validation_method = "DNS"
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  tags = {
    Name           = "certWordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_acm_certificate_validation" "Validation_certAlb" {
  certificate_arn         = aws_acm_certificate.certAlb.arn
  validation_record_fqdns = [for record in aws_route53_record.Route53_Record_certAlb_origin_wp_cloudman_pro : record.fqdn]
}

resource "aws_acm_certificate_validation" "Validation_certWordpress" {
  certificate_arn         = aws_acm_certificate.certWordpress.arn
  region                  = "us-east-1"
  validation_record_fqdns = [for record in aws_route53_record.Route53_Record_certWordpress_wp_cloudman_pro : record.fqdn]
}
