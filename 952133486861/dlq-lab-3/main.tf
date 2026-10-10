terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/dlq-lab-3/main.tfstate"
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

### CATEGORY: IAM ###

data "aws_iam_policy_document" "lambda_function_dlq-lab-consumer-3_st_dlq-lab-3_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-consumer-logs-3.arn}:*"]
  }
  statement {
    sid       = "AllowEventSourceRead"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
    resources = [aws_sqs_queue.dlq-lab-orders-queue-3.arn]
  }
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-consumer-3_st_dlq-lab-3" {
  name        = "lambda_function_dlq-lab-consumer-3_st_dlq-lab-3"
  description = "Access Policy for dlq-lab-consumer-3"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-consumer-3_st_dlq-lab-3_doc.json
}

data "aws_iam_policy_document" "lambda_function_dlq-lab-legacy-notifier-3_st_dlq-lab-3_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-legacy-notifier-logs-3.arn}:*"]
  }
  statement {
    sid       = "AllowSQSActions"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq-lab-legacy-dlq-3.arn]
  }
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-legacy-notifier-3_st_dlq-lab-3" {
  name        = "lambda_function_dlq-lab-legacy-notifier-3_st_dlq-lab-3"
  description = "Access Policy for dlq-lab-legacy-notifier-3"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-legacy-notifier-3_st_dlq-lab-3_doc.json
}

data "aws_iam_policy_document" "lambda_function_dlq-lab-notifier-3_st_dlq-lab-3_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-notifier-logs-3.arn}:*"]
  }
  statement {
    sid       = "AllowFailureDestination"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq-lab-notifier-failed-3.arn]
  }
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-notifier-3_st_dlq-lab-3" {
  name        = "lambda_function_dlq-lab-notifier-3_st_dlq-lab-3"
  description = "Access Policy for dlq-lab-notifier-3"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-notifier-3_st_dlq-lab-3_doc.json
}

data "aws_iam_policy_document" "lambda_function_dlq-lab-producer-3_st_dlq-lab-3_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-producer-logs-3.arn}:*"]
  }
  statement {
    sid       = "AllowSNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.dlq-lab-orders-3.arn]
  }
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-producer-3_st_dlq-lab-3" {
  name        = "lambda_function_dlq-lab-producer-3_st_dlq-lab-3"
  description = "Access Policy for dlq-lab-producer-3"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-producer-3_st_dlq-lab-3_doc.json
}

data "aws_iam_policy_document" "scheduler_schedule_dlq-lab-traffic-ok-3_st_dlq-lab-3_doc" {
  statement {
    sid       = "AllowSchedulerToPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.dlq-lab-orders-3.arn]
  }
}

resource "aws_iam_policy" "scheduler_schedule_dlq-lab-traffic-ok-3_st_dlq-lab-3" {
  name        = "scheduler_schedule_dlq-lab-traffic-ok-3_st_dlq-lab-3"
  description = "Access Policy for dlq-lab-traffic-ok-3"
  policy      = data.aws_iam_policy_document.scheduler_schedule_dlq-lab-traffic-ok-3_st_dlq-lab-3_doc.json
}

resource "aws_iam_role" "dlq-lab-consumer-3_role" {
  name = "dlq-lab-consumer-3_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "dlq-lab-consumer-3_role"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-legacy-notifier-3_role" {
  name = "dlq-lab-legacy-notifier-3_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "dlq-lab-legacy-notifier-3_role"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-notifier-3_role" {
  name = "dlq-lab-notifier-3_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "dlq-lab-notifier-3_role"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-producer-3_role" {
  name = "dlq-lab-producer-3_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "dlq-lab-producer-3_role"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-traffic-ok-3_role" {
  name = "dlq-lab-traffic-ok-3_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "scheduler.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "dlq-lab-traffic-ok-3_role"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-consumer-3_st_dlq-lab-3_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-consumer-3_st_dlq-lab-3.arn
  role       = aws_iam_role.dlq-lab-consumer-3_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-legacy-notifier-3_st_dlq-lab-3_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-legacy-notifier-3_st_dlq-lab-3.arn
  role       = aws_iam_role.dlq-lab-legacy-notifier-3_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-notifier-3_st_dlq-lab-3_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-notifier-3_st_dlq-lab-3.arn
  role       = aws_iam_role.dlq-lab-notifier-3_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-producer-3_st_dlq-lab-3_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-producer-3_st_dlq-lab-3.arn
  role       = aws_iam_role.dlq-lab-producer-3_role.name
}

resource "aws_iam_role_policy_attachment" "scheduler_schedule_dlq-lab-traffic-ok-3_st_dlq-lab-3_attach" {
  policy_arn = aws_iam_policy.scheduler_schedule_dlq-lab-traffic-ok-3_st_dlq-lab-3.arn
  role       = aws_iam_role.dlq-lab-traffic-ok-3_role.name
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_event_source_mapping" "dlq-lab-orders-esm-3" {
  function_name                      = aws_lambda_function.dlq-lab-consumer-3.arn
  batch_size                         = 10
  event_source_arn                   = aws_sqs_queue.dlq-lab-orders-queue-3.arn
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 5
  metrics_config {
    metrics = ["EventCount"]
  }
  tags = {
    Name           = "dlq-lab-orders-esm-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_struct8-hub_dlq-lab-consumer-3" {
  output_path = "${path.module}/struct8-hub_dlq-lab-consumer-3.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-consumer-3" {
  function_name                  = "dlq-lab-consumer-3"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-hub_dlq-lab-consumer-3.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-consumer-3_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_dlq-lab-consumer-3.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    HUB_FAULTS            = "on"
    NAME                  = "dlq-lab-consumer-3"
    REGION                = data.aws_region.current.region
    ACCOUNT               = data.aws_caller_identity.current.account_id
    AWS_XRAY_GROUP_NAME_0 = "dlq-lab-traces-3"
  }
  }
  tags = {
    Name           = "dlq-lab-consumer-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
  tracing_config {
    mode = "Active"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-consumer-3_st_dlq-lab-3_attach]
}

data "archive_file" "archive_struct8-hub_dlq-lab-legacy-notifier-3" {
  output_path = "${path.module}/struct8-hub_dlq-lab-legacy-notifier-3.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-legacy-notifier-3" {
  function_name                  = "dlq-lab-legacy-notifier-3"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-hub_dlq-lab-legacy-notifier-3.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-legacy-notifier-3_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_dlq-lab-legacy-notifier-3.output_base64sha256
  timeout                        = 10
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq-lab-legacy-dlq-3.arn
  }
  environment {
    variables = {
    HUB_FAULTS            = "on"
    NAME                  = "dlq-lab-legacy-notifier-3"
    REGION                = data.aws_region.current.region
    ACCOUNT               = data.aws_caller_identity.current.account_id
    AWS_XRAY_GROUP_NAME_0 = "dlq-lab-traces-3"
  }
  }
  tags = {
    Name           = "dlq-lab-legacy-notifier-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
  tracing_config {
    mode = "Active"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-legacy-notifier-3_st_dlq-lab-3_attach]
}

data "archive_file" "archive_struct8-hub_dlq-lab-notifier-3" {
  output_path = "${path.module}/struct8-hub_dlq-lab-notifier-3.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-notifier-3" {
  function_name                  = "dlq-lab-notifier-3"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-hub_dlq-lab-notifier-3.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-notifier-3_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_dlq-lab-notifier-3.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    HUB_FAULTS                                     = "on"
    NAME                                           = "dlq-lab-notifier-3"
    REGION                                         = data.aws_region.current.region
    ACCOUNT                                        = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_EVENT_INVOKE_CONFIG_NAME_0 = "dlq-lab-notifier-async-3"
    AWS_XRAY_GROUP_NAME_0                          = "dlq-lab-traces-3"
  }
  }
  tags = {
    Name           = "dlq-lab-notifier-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
  tracing_config {
    mode = "Active"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-notifier-3_st_dlq-lab-3_attach]
}

data "archive_file" "archive_struct8-templates_dlq-lab-producer-3" {
  output_path = "${path.module}/struct8-templates_dlq-lab-producer-3.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/sqs-sns-dlq-lab/v1/lambda/dlq-lab-producer"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-producer-3" {
  function_name                  = "dlq-lab-producer-3"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_dlq-lab-producer-3.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-producer-3_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_dlq-lab-producer-3.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                           = "dlq-lab-producer-3"
    REGION                         = data.aws_region.current.region
    ACCOUNT                        = data.aws_caller_identity.current.account_id
    AWS_SNS_TOPIC_NAME_0           = "dlq-lab-orders-3"
    AWS_LAMBDA_FUNCTION_URL_NAME_0 = "dlq-lab-producer-url-3"
    AWS_XRAY_GROUP_NAME_0          = "dlq-lab-traces-3"
  }
  }
  tags = {
    Name           = "dlq-lab-producer-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
  tracing_config {
    mode = "Active"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-producer-3_st_dlq-lab-3_attach]
}

resource "aws_lambda_function_event_invoke_config" "dlq-lab-notifier-async-3" {
  function_name                = aws_lambda_function.dlq-lab-notifier-3.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
  destination_config {
    on_failure {
      destination = aws_sqs_queue.dlq-lab-notifier-failed-3.arn
    }
  }
}

resource "aws_lambda_function_url" "dlq-lab-producer-url-3" {
  function_name      = aws_lambda_function.dlq-lab-producer-3.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_dlq-lab-producer-url-3_to_dlq-lab-producer-3" {
  function_name          = aws_lambda_function.dlq-lab-producer-3.function_name
  statement_id           = "perm_aws_lambda_function_url_dlq-lab-producer-url-3_to_dlq-lab-producer-3"
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_dlq-lab-producer-url-3_to_dlq-lab-producer-3_invoke" {
  function_name            = aws_lambda_function.dlq-lab-producer-3.function_name
  statement_id             = "perm_aws_lambda_function_url_dlq-lab-producer-url-3_to_dlq-lab-producer-3_invoke"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
}

resource "aws_lambda_permission" "perm_aws_sns_topic_dlq-lab-orders-3_to_dlq-lab-legacy-notifier-3" {
  function_name = aws_lambda_function.dlq-lab-legacy-notifier-3.function_name
  statement_id  = "perm_aws_sns_topic_dlq-lab-orders-3_to_dlq-lab-legacy-notifier-3"
  principal     = "sns.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_sns_topic.dlq-lab-orders-3.arn
}

resource "aws_lambda_permission" "perm_aws_sns_topic_dlq-lab-orders-3_to_dlq-lab-notifier-3" {
  function_name = aws_lambda_function.dlq-lab-notifier-3.function_name
  statement_id  = "perm_aws_sns_topic_dlq-lab-orders-3_to_dlq-lab-notifier-3"
  principal     = "sns.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_sns_topic.dlq-lab-orders-3.arn
}




### CATEGORY: INTEGRATION ###

resource "aws_sqs_queue" "dlq-lab-legacy-dlq-3" {
  name                              = "dlq-lab-legacy-dlq-3"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "dlq-lab-legacy-dlq-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "dlq-lab-notifier-failed-3" {
  name                              = "dlq-lab-notifier-failed-3"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "dlq-lab-notifier-failed-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "dlq-lab-orders-dlq-3" {
  name                              = "dlq-lab-orders-dlq-3"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 1209600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "dlq-lab-orders-dlq-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "dlq-lab-orders-queue-3" {
  name                              = "dlq-lab-orders-queue-3"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  redrive_policy                    = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dlq-lab-orders-dlq-3.arn, maxReceiveCount = 3 })
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 60
  tags = {
    Name           = "dlq-lab-orders-queue-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "aws_sqs_queue_policy_dlq-lab-orders-queue-3_st_dlq-lab-3_doc" {
  statement {
    sid    = "AllowSQSActions"
    effect = "Allow"
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq-lab-orders-queue-3.arn]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
}

resource "aws_sqs_queue_policy" "aws_sqs_queue_policy_dlq-lab-orders-queue-3_st_dlq-lab-3" {
  policy    = data.aws_iam_policy_document.aws_sqs_queue_policy_dlq-lab-orders-queue-3_st_dlq-lab-3_doc.json
  queue_url = aws_sqs_queue.dlq-lab-orders-queue-3.id
}

resource "aws_sns_topic" "dlq-lab-alerts-3" {
  name           = "dlq-lab-alerts-3"
  tracing_config = "Active"
  tags = {
    Name           = "dlq-lab-alerts-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_xray_resource_policy.aws_xray_resource_policy_st_dlq-lab-3_c9902ade90]
}

resource "aws_sns_topic" "dlq-lab-orders-3" {
  name           = "dlq-lab-orders-3"
  tracing_config = "Active"
  tags = {
    Name           = "dlq-lab-orders-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_sqs_queue_policy.aws_sqs_queue_policy_dlq-lab-orders-queue-3_st_dlq-lab-3, aws_xray_resource_policy.aws_xray_resource_policy_st_dlq-lab-3_c9902ade90]
}

resource "aws_sns_topic_subscription" "Subscription2-3" {
  endpoint   = aws_lambda_function.dlq-lab-notifier-3.arn
  protocol   = "lambda"
  topic_arn  = aws_sns_topic.dlq-lab-orders-3.arn
  depends_on = [aws_lambda_permission.perm_aws_sns_topic_dlq-lab-orders-3_to_dlq-lab-notifier-3]
}

resource "aws_sns_topic_subscription" "Subscription3-3" {
  endpoint   = aws_lambda_function.dlq-lab-legacy-notifier-3.arn
  protocol   = "lambda"
  topic_arn  = aws_sns_topic.dlq-lab-orders-3.arn
  depends_on = [aws_lambda_permission.perm_aws_sns_topic_dlq-lab-orders-3_to_dlq-lab-legacy-notifier-3]
}

resource "aws_sns_topic_subscription" "Subscription4-3" {
  endpoint  = aws_sqs_queue.dlq-lab-orders-queue-3.arn
  protocol  = "sqs"
  topic_arn = aws_sns_topic.dlq-lab-orders-3.arn
}

resource "aws_sns_topic_subscription" "dlq-lab-alerts-email-3" {
  endpoint  = "contact@struct8.com"
  protocol  = "email"
  topic_arn = aws_sns_topic.dlq-lab-alerts-3.arn
}

resource "aws_scheduler_schedule" "dlq-lab-traffic-ok-3" {
  name                = "dlq-lab-traffic-ok-3"
  schedule_expression = "rate(1 minute)"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_sns_topic.dlq-lab-orders-3.arn
    input    = "{\"behavior\":\"ok\"}"
    role_arn = aws_iam_role.dlq-lab-traffic-ok-3_role.arn
    retry_policy {
      maximum_event_age_in_seconds = 60
      maximum_retry_attempts       = 0
    }
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_schedule_dlq-lab-traffic-ok-3_st_dlq-lab-3_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "dlq-lab-consumer-logs-3" {
  name              = "/aws/lambda/dlq-lab-consumer"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-consumer-logs-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "dlq-lab-legacy-notifier-logs-3" {
  name              = "/aws/lambda/dlq-lab-legacy-notifier"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-legacy-notifier-logs-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "dlq-lab-notifier-logs-3" {
  name              = "/aws/lambda/dlq-lab-notifier"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-notifier-logs-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "dlq-lab-producer-logs-3" {
  name              = "/aws/lambda/dlq-lab-producer"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-producer-logs-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq-lab-orders-dlq-not-empty-3" {
  alarm_name          = "dlq-lab-orders-dlq-not-empty-3"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  alarm_actions       = [aws_sns_topic.dlq-lab-alerts-3.arn]
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  dimensions = {
    QueueName = aws_sqs_queue.dlq-lab-orders-dlq-3.name
  }
  tags = {
    Name           = "dlq-lab-orders-dlq-not-empty-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_xray_group" "dlq-lab-traces-3" {
  group_name        = "dlq-lab-traces-3"
  filter_expression = "service(\"dlq-lab-alerts-3\") OR service(\"dlq-lab-consumer-3\") OR service(\"dlq-lab-legacy-notifier-3\") OR service(\"dlq-lab-notifier-3\") OR service(\"dlq-lab-orders-3\") OR service(\"dlq-lab-producer-3\")"
  tags = {
    Name           = "dlq-lab-traces-3"
    State          = "dlq-lab-3"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "aws_xray_resource_policy_st_dlq-lab-3_c9902ade90_doc" {
  statement {
    sid    = "AllowSNSToSendTracesToXRay"
    effect = "Allow"
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["xray:GetSamplingRules", "xray:GetSamplingTargets", "xray:PutTraceSegments"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "StringLike"
      values   = ["arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_xray_resource_policy" "aws_xray_resource_policy_st_dlq-lab-3_c9902ade90" {
  policy_name     = "aws_xray_resource_policy_st_dlq-lab-3_c9902ade90"
  policy_document = data.aws_iam_policy_document.aws_xray_resource_policy_st_dlq-lab-3_c9902ade90_doc.json
}


