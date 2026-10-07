terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    time = {
      source = "hashicorp/time"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/codebuild-lab-ci/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### EXTERNAL REFERENCES ###

locals {
  aws_codebuild_project_codebuild_lab_integration_arn  = "arn:aws:codebuild:us-west-2:952133486861:project/codebuild-lab-integration"
  aws_codebuild_project_codebuild_lab_integration_name = "codebuild-lab-integration"
}

data "aws_codestarconnections_connection" "codebuild-lab-github" {
  name = "codebuild-lab-github"
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.codebuild-lab-pr-check-logs.arn}:*"]
  }
  statement {
    sid       = "AllowUseOfConnection"
    effect    = "Allow"
    actions   = ["codeconnections:GetConnection", "codeconnections:GetConnectionToken", "codestar-connections:GetConnection", "codestar-connections:GetConnectionToken"]
    resources = [data.aws_codestarconnections_connection.codebuild-lab-github.arn]
  }
  statement {
    sid       = "PublishTestReportsOfThisProject"
    effect    = "Allow"
    actions   = ["codebuild:BatchPutCodeCoverages", "codebuild:BatchPutTestCases", "codebuild:CreateReport", "codebuild:CreateReportGroup", "codebuild:UpdateReport"]
    resources = ["arn:aws:codebuild:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:report-group/codebuild-lab-pr-check-*"]
  }
}

resource "aws_iam_policy" "codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci" {
  name        = "codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci"
  description = "Access Policy for codebuild-lab-pr-check"
  policy      = data.aws_iam_policy_document.codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci_doc.json
}

data "aws_iam_policy_document" "codebuild_project_codebuild-lab-release_st_codebuild-lab-ci_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.codebuild-lab-release-logs.arn}:*"]
  }
  statement {
    sid       = "AllowUseOfConnection"
    effect    = "Allow"
    actions   = ["codeconnections:GetConnection", "codeconnections:GetConnectionToken", "codestar-connections:GetConnection", "codestar-connections:GetConnectionToken"]
    resources = [data.aws_codestarconnections_connection.codebuild-lab-github.arn]
  }
  statement {
    sid       = "AllowPullFromRepository"
    effect    = "Allow"
    actions   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:CompleteLayerUpload", "ecr:GetDownloadUrlForLayer", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart"]
    resources = [aws_ecr_repository.codebuild-lab-orders.arn]
  }
  statement {
    sid       = "AllowKMSAccess"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.codebuild-lab-artifacts-key.arn]
  }
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.codebuild-lab-artifacts.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    resources = ["${aws_s3_bucket.codebuild-lab-artifacts.arn}/*"]
  }
  statement {
    sid       = "AllowBucketLevelActions1"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.codebuild-lab-cache.arn]
  }
  statement {
    sid       = "AllowObjectCRUD1"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    resources = ["${aws_s3_bucket.codebuild-lab-cache.arn}/*"]
  }
  statement {
    sid       = "AllowEcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid       = "PublishTestReportsOfThisProject"
    effect    = "Allow"
    actions   = ["codebuild:BatchPutCodeCoverages", "codebuild:BatchPutTestCases", "codebuild:CreateReport", "codebuild:CreateReportGroup", "codebuild:UpdateReport"]
    resources = ["arn:aws:codebuild:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:report-group/codebuild-lab-release-*"]
  }
}

resource "aws_iam_policy" "codebuild_project_codebuild-lab-release_st_codebuild-lab-ci" {
  name        = "codebuild_project_codebuild-lab-release_st_codebuild-lab-ci"
  description = "Access Policy for codebuild-lab-release"
  policy      = data.aws_iam_policy_document.codebuild_project_codebuild-lab-release_st_codebuild-lab-ci_doc.json
}

data "aws_iam_policy_document" "codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.codebuild-lab-runner-logs.arn}:*"]
  }
  statement {
    sid       = "AllowUseOfConnection"
    effect    = "Allow"
    actions   = ["codeconnections:GetConnection", "codeconnections:GetConnectionToken", "codestar-connections:GetConnection", "codestar-connections:GetConnectionToken"]
    resources = [data.aws_codestarconnections_connection.codebuild-lab-github.arn]
  }
  statement {
    sid       = "PublishTestReportsOfThisProject"
    effect    = "Allow"
    actions   = ["codebuild:BatchPutCodeCoverages", "codebuild:BatchPutTestCases", "codebuild:CreateReport", "codebuild:CreateReportGroup", "codebuild:UpdateReport"]
    resources = ["arn:aws:codebuild:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:report-group/codebuild-lab-runner-*"]
  }
}

resource "aws_iam_policy" "codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci" {
  name        = "codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci"
  description = "Access Policy for codebuild-lab-runner"
  policy      = data.aws_iam_policy_document.codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci_doc.json
}

resource "aws_iam_role" "codebuild-lab-pr-check_role" {
  name = "codebuild-lab-pr-check_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "codebuild-lab-pr-check_role"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "codebuild-lab-release_role" {
  name = "codebuild-lab-release_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "codebuild-lab-release_role"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "codebuild-lab-runner_role" {
  name = "codebuild-lab-runner_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "codebuild-lab-runner_role"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_eventbridge_codebuild-lab-release-succeeded" {
  name = "role_eventbridge_codebuild-lab-release-succeeded"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      }
    }
  ]
})
  tags = {
    Name           = "role_eventbridge_codebuild-lab-release-succeeded"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci_attach" {
  policy_arn = aws_iam_policy.codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci.arn
  role       = aws_iam_role.codebuild-lab-pr-check_role.name
}

resource "aws_iam_role_policy_attachment" "codebuild_project_codebuild-lab-release_st_codebuild-lab-ci_attach" {
  policy_arn = aws_iam_policy.codebuild_project_codebuild-lab-release_st_codebuild-lab-ci.arn
  role       = aws_iam_role.codebuild-lab-release_role.name
}

resource "aws_iam_role_policy_attachment" "codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci_attach" {
  policy_arn = aws_iam_policy.codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci.arn
  role       = aws_iam_role.codebuild-lab-runner_role.name
}

resource "aws_kms_key" "codebuild-lab-artifacts-key" {
  bypass_policy_lockout_safety_check = false
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  deletion_window_in_days            = 30
  enable_key_rotation                = true
  is_enabled                         = true
  key_usage                          = "ENCRYPT_DECRYPT"
  multi_region                       = false
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
  EOF
  rotation_period_in_days = 365
  tags = {
    Name           = "codebuild-lab-artifacts-key"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "codebuild-lab-artifacts" {
  bucket              = "codebuild-lab-artifacts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "codebuild-lab-artifacts"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "codebuild-lab-cache" {
  bucket              = "codebuild-lab-cache-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "codebuild-lab-cache"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "codebuild-lab-artifacts_controls" {
  bucket = aws_s3_bucket.codebuild-lab-artifacts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "codebuild-lab-cache_controls" {
  bucket = aws_s3_bucket.codebuild-lab-cache.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "codebuild-lab-artifacts_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.codebuild-lab-artifacts.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "codebuild-lab-cache_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.codebuild-lab-cache.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild-lab-artifacts_configuration" {
  bucket = aws_s3_bucket.codebuild-lab-artifacts.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild-lab-cache_configuration" {
  bucket = aws_s3_bucket.codebuild-lab-cache.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "codebuild-lab-artifacts_versioning" {
  bucket = aws_s3_bucket.codebuild-lab-artifacts.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "codebuild-lab-cache_versioning" {
  bucket = aws_s3_bucket.codebuild-lab-cache.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}




### CATEGORY: CONTAINERS ###

resource "aws_ecr_repository" "codebuild-lab-orders" {
  name                 = "codebuild-lab-orders"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  tags = {
    Name           = "codebuild-lab-orders"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: INTEGRATION ###

resource "aws_sns_topic" "codebuild-lab-notifications" {
  name = "codebuild-lab-notifications"
  tags = {
    Name           = "codebuild-lab-notifications"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "aws_sns_topic_policy_codebuild-lab-notifications_st_codebuild-lab-ci_doc" {
  statement {
    sid    = "AllowEventBridgeToPublishToSNS"
    effect = "Allow"
    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.codebuild-lab-notifications.arn]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
}

resource "aws_sns_topic_policy" "aws_sns_topic_policy_codebuild-lab-notifications_st_codebuild-lab-ci" {
  arn    = aws_sns_topic.codebuild-lab-notifications.arn
  policy = data.aws_iam_policy_document.aws_sns_topic_policy_codebuild-lab-notifications_st_codebuild-lab-ci_doc.json
}

resource "aws_sns_topic_subscription" "codebuild-lab-email" {
  endpoint  = "contact@struct8.com"
  protocol  = "email"
  topic_arn = aws_sns_topic.codebuild-lab-notifications.arn
}

resource "aws_cloudwatch_event_rule" "codebuild-lab-build-finished" {
  name        = "codebuild-lab-build-finished"
  description = "Every finished build of the lab projects, sent to the notifications topic."
  event_pattern = <<EOF
{
  "source": [
    "aws.codebuild"
  ],
  "detail-type": [
    "CodeBuild Build State Change"
  ],
  "detail": {
    "build-status": [
      "SUCCEEDED",
      "FAILED",
      "STOPPED"
    ],
    "project-name": [
      "${aws_codebuild_project.codebuild-lab-pr-check.name}",
      "${aws_codebuild_project.codebuild-lab-release.name}",
      "${aws_codebuild_project.codebuild-lab-runner.name}",
      "${local.aws_codebuild_project_codebuild_lab_integration_name}"
    ]
  }
}
  EOF
  state = "ENABLED"
  tags = {
    Name           = "codebuild-lab-build-finished"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_sns_topic_policy.aws_sns_topic_policy_codebuild-lab-notifications_st_codebuild-lab-ci]
}

resource "aws_cloudwatch_event_rule" "codebuild-lab-release-succeeded" {
  name        = "codebuild-lab-release-succeeded"
  description = "A release build that succeeded starts the integration tests."
  event_pattern = <<EOF
{
  "source": [
    "aws.codebuild"
  ],
  "detail-type": [
    "CodeBuild Build State Change"
  ],
  "detail": {
    "build-status": [
      "SUCCEEDED"
    ],
    "project-name": [
      "${aws_codebuild_project.codebuild-lab-release.name}"
    ]
  }
}
  EOF
  state = "ENABLED"
  tags = {
    Name           = "codebuild-lab-release-succeeded"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_event_target" "notify-email" {
  arn  = aws_sns_topic.codebuild-lab-notifications.arn
  rule = aws_cloudwatch_event_rule.codebuild-lab-build-finished.name
  input_transformer {
    input_template = "\"CodeBuild <project>: <status> at <time>. Build <build>\""
    input_paths = {
    project = "$.detail.project-name"
    status  = "$.detail.build-status"
    build   = "$.detail.build-id"
    time    = "$.time"
  }
  }
}

resource "aws_cloudwatch_event_target" "release-integration" {
  arn      = local.aws_codebuild_project_codebuild_lab_integration_arn
  role_arn = aws_iam_role.role_eventbridge_codebuild-lab-release-succeeded.arn
  rule     = aws_cloudwatch_event_rule.codebuild-lab-release-succeeded.name
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "codebuild-lab-pr-check-logs" {
  name              = "/aws/codebuild/codebuild-lab-pr-check"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "codebuild-lab-pr-check-logs"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "codebuild-lab-release-logs" {
  name              = "/aws/codebuild/codebuild-lab-release"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "codebuild-lab-release-logs"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "codebuild-lab-runner-logs" {
  name              = "/aws/codebuild/codebuild-lab-runner"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "codebuild-lab-runner-logs"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "codebuild-lab-failed-builds" {
  alarm_name          = "codebuild-lab-failed-builds"
  alarm_actions       = [aws_sns_topic.codebuild-lab-notifications.arn]
  alarm_description   = "A pull request check or a release build failed."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"
  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())"
    return_data = true
  }
  metric_query {
    id = "m1"
    metric {
      metric_name = "FailedBuilds"
      namespace   = "AWS/CodeBuild"
      period      = 300
      stat        = "Sum"
      dimensions = {
    ProjectName = aws_codebuild_project.codebuild-lab-pr-check.name
  }
    }
  }
  metric_query {
    id = "m2"
    metric {
      metric_name = "FailedBuilds"
      namespace   = "AWS/CodeBuild"
      period      = 300
      stat        = "Sum"
      dimensions = {
    ProjectName = aws_codebuild_project.codebuild-lab-release.name
  }
    }
  }
  tags = {
    Name           = "codebuild-lab-failed-builds"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DEVTOOLS ###

resource "aws_codebuild_project" "codebuild-lab-pr-check" {
  source {
    buildspec           = "buildspec/pr-check.yml"
    git_clone_depth     = 1
    location            = "https://github.com/Struct8/codebuild-lab.git"
    report_build_status = true
    type                = "GITHUB"
    auth {
      resource = data.aws_codestarconnections_connection.codebuild-lab-github.arn
      type     = "CODECONNECTIONS"
    }
  }
  name             = "codebuild-lab-pr-check"
  auto_retry_limit = 0
  build_timeout    = 15
  description      = "Unit tests and coverage of each pull request on Lambda compute."
  service_role     = aws_iam_role.codebuild-lab-pr-check_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_LAMBDA_1GB"
    image        = "aws/codebuild/amazonlinux-x86_64-lambda-standard:nodejs22"
    type         = "LINUX_LAMBDA_CONTAINER"
    environment_variable {
      name  = "NAME"
      type  = "PLAINTEXT"
      value = "codebuild-lab-pr-check"
    }
    environment_variable {
      name  = "REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.current.region
    }
    environment_variable {
      name  = "ACCOUNT"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_ARN_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.arn
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_NAME_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.name
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild-lab-pr-check-logs.name
      status     = "ENABLED"
    }
  }
  tags = {
    Name           = "codebuild-lab-pr-check"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci_attach, time_sleep.codebuild-lab-pr-check_role_propagation]
}

resource "aws_codebuild_project" "codebuild-lab-release" {
  source {
    buildspec           = "buildspec/release.yml"
    git_clone_depth     = 1
    location            = "https://github.com/Struct8/codebuild-lab.git"
    report_build_status = true
    type                = "GITHUB"
    auth {
      resource = data.aws_codestarconnections_connection.codebuild-lab-github.arn
      type     = "CODECONNECTIONS"
    }
  }
  name                   = "codebuild-lab-release"
  auto_retry_limit       = 0
  badge_enabled          = true
  build_timeout          = 30
  concurrent_build_limit = 1
  description            = "Image to ECR tagged with the commit and release zip to S3 on each push to main."
  encryption_key         = aws_kms_key.codebuild-lab-artifacts-key.arn
  service_role           = aws_iam_role.codebuild-lab-release_role.arn
  artifacts {
    name           = "release.zip"
    location       = aws_s3_bucket.codebuild-lab-artifacts.bucket
    namespace_type = "BUILD_ID"
    packaging      = "ZIP"
    type           = "S3"
  }
  cache {
    location = aws_s3_bucket.codebuild-lab-cache.bucket
    type     = "S3"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux-x86_64-standard:6.0"
    privileged_mode = true
    type            = "LINUX_CONTAINER"
    environment_variable {
      name  = "IMAGE_REPO_URL"
      type  = "PLAINTEXT"
      value = aws_ecr_repository.codebuild-lab-orders.repository_url
    }
    environment_variable {
      name  = "NAME"
      type  = "PLAINTEXT"
      value = "codebuild-lab-release"
    }
    environment_variable {
      name  = "REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.current.region
    }
    environment_variable {
      name  = "ACCOUNT"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_ARN_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.arn
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_NAME_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.name
    }
    environment_variable {
      name  = "AWS_S3_BUCKET_NAME_0"
      type  = "PLAINTEXT"
      value = "codebuild-lab-cache-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
    }
    environment_variable {
      name  = "AWS_KMS_KEY_NAME_0"
      type  = "PLAINTEXT"
      value = "codebuild-lab-artifacts-key"
    }
    environment_variable {
      name  = "AWS_ECR_REPOSITORY_NAME_0"
      type  = "PLAINTEXT"
      value = "codebuild-lab-orders"
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild-lab-release-logs.name
      status     = "ENABLED"
    }
  }
  tags = {
    Name           = "codebuild-lab-release"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.codebuild_project_codebuild-lab-release_st_codebuild-lab-ci_attach, time_sleep.codebuild-lab-release_role_propagation]
}

resource "aws_codebuild_project" "codebuild-lab-runner" {
  source {
    git_clone_depth = 1
    location        = "https://github.com/Struct8/codebuild-lab.git"
    type            = "GITHUB"
    auth {
      resource = data.aws_codestarconnections_connection.codebuild-lab-github.arn
      type     = "CODECONNECTIONS"
    }
  }
  name             = "codebuild-lab-runner"
  auto_retry_limit = 0
  build_timeout    = 30
  description      = "Runs the GitHub Actions jobs whose runs-on label names this project."
  service_role     = aws_iam_role.codebuild-lab-runner_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
    type         = "ARM_CONTAINER"
    environment_variable {
      name  = "NAME"
      type  = "PLAINTEXT"
      value = "codebuild-lab-runner"
    }
    environment_variable {
      name  = "REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.current.region
    }
    environment_variable {
      name  = "ACCOUNT"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_ARN_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.arn
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_NAME_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.codebuild-lab-github.name
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild-lab-runner-logs.name
      status     = "ENABLED"
    }
  }
  tags = {
    Name           = "codebuild-lab-runner"
    State          = "codebuild-lab-ci"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci_attach, time_sleep.codebuild-lab-runner_role_propagation]
}

resource "aws_codebuild_webhook" "codebuild-lab-pr-check_webhook" {
  project_name = aws_codebuild_project.codebuild-lab-pr-check.name
  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED"
      type                    = "EVENT"
    }
    filter {
      exclude_matched_pattern = false
      pattern                 = "^refs/heads/main$"
      type                    = "BASE_REF"
    }
  }
}

resource "aws_codebuild_webhook" "codebuild-lab-release_webhook" {
  project_name = aws_codebuild_project.codebuild-lab-release.name
  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "PUSH"
      type                    = "EVENT"
    }
    filter {
      exclude_matched_pattern = false
      pattern                 = "^refs/heads/main$"
      type                    = "HEAD_REF"
    }
  }
}

resource "aws_codebuild_webhook" "codebuild-lab-runner_webhook" {
  project_name = aws_codebuild_project.codebuild-lab-runner.name
  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "WORKFLOW_JOB_QUEUED"
      type                    = "EVENT"
    }
  }
}




### CATEGORY: MISC ###

resource "time_sleep" "codebuild-lab-pr-check_role_propagation" {
  create_duration = "30s"
  triggers = {
    policy_attachment = aws_iam_role_policy_attachment.codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci_attach.id
    policy            = aws_iam_policy.codebuild_project_codebuild-lab-pr-check_st_codebuild-lab-ci.policy
  }
}

resource "time_sleep" "codebuild-lab-release_role_propagation" {
  create_duration = "30s"
  triggers = {
    policy_attachment = aws_iam_role_policy_attachment.codebuild_project_codebuild-lab-release_st_codebuild-lab-ci_attach.id
    policy            = aws_iam_policy.codebuild_project_codebuild-lab-release_st_codebuild-lab-ci.policy
  }
}

resource "time_sleep" "codebuild-lab-runner_role_propagation" {
  create_duration = "30s"
  triggers = {
    policy_attachment = aws_iam_role_policy_attachment.codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci_attach.id
    policy            = aws_iam_policy.codebuild_project_codebuild-lab-runner_st_codebuild-lab-ci.policy
  }
}


