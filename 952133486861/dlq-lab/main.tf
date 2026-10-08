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
    key     = "952133486861/dlq-lab/main.tfstate"
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

data "aws_iam_policy_document" "lambda_function_dlq-lab-consumer_st_dlq-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-consumer-logs.arn}:*"]
  }
  statement {
    sid       = "AllowEventSourceRead"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
    resources = [aws_sqs_queue.dlq-lab-orders-queue.arn]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-consumer_st_dlq-lab" {
  name        = "lambda_function_dlq-lab-consumer_st_dlq-lab"
  description = "Access Policy for dlq-lab-consumer"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-consumer_st_dlq-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_dlq-lab-legacy-notifier_st_dlq-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-legacy-notifier-logs.arn}:*"]
  }
  statement {
    sid       = "AllowSQSActions"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq-lab-legacy-dlq.arn]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-legacy-notifier_st_dlq-lab" {
  name        = "lambda_function_dlq-lab-legacy-notifier_st_dlq-lab"
  description = "Access Policy for dlq-lab-legacy-notifier"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-legacy-notifier_st_dlq-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_dlq-lab-notifier_st_dlq-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-notifier-logs.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-notifier_st_dlq-lab" {
  name        = "lambda_function_dlq-lab-notifier_st_dlq-lab"
  description = "Access Policy for dlq-lab-notifier"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-notifier_st_dlq-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_dlq-lab-producer_st_dlq-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dlq-lab-producer-logs.arn}:*"]
  }
  statement {
    sid       = "AllowSNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.dlq-lab-orders.arn]
  }
  statement {
    sid       = "AllowSQSActions"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq-lab-orders-queue.arn]
  }
}

resource "aws_iam_policy" "lambda_function_dlq-lab-producer_st_dlq-lab" {
  name        = "lambda_function_dlq-lab-producer_st_dlq-lab"
  description = "Access Policy for dlq-lab-producer"
  policy      = data.aws_iam_policy_document.lambda_function_dlq-lab-producer_st_dlq-lab_doc.json
}

data "aws_iam_policy_document" "scheduler_schedule_dlq-lab-traffic-ok_st_dlq-lab_doc" {
  statement {
    sid       = "AllowSchedulerToPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.dlq-lab-orders.arn]
  }
  statement {
    sid       = "AllowSchedulerToSendMessage"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq-lab-scheduler-dlq.arn]
  }
}

resource "aws_iam_policy" "scheduler_schedule_dlq-lab-traffic-ok_st_dlq-lab" {
  name        = "scheduler_schedule_dlq-lab-traffic-ok_st_dlq-lab"
  description = "Access Policy for dlq-lab-traffic-ok"
  policy      = data.aws_iam_policy_document.scheduler_schedule_dlq-lab-traffic-ok_st_dlq-lab_doc.json
}

resource "aws_iam_role" "dlq-lab-consumer_role" {
  name = "dlq-lab-consumer_role"
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
    Name           = "dlq-lab-consumer_role"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-legacy-notifier_role" {
  name = "dlq-lab-legacy-notifier_role"
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
    Name           = "dlq-lab-legacy-notifier_role"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-notifier_role" {
  name = "dlq-lab-notifier_role"
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
    Name           = "dlq-lab-notifier_role"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-producer_role" {
  name = "dlq-lab-producer_role"
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
    Name           = "dlq-lab-producer_role"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "dlq-lab-traffic-ok_role" {
  name = "dlq-lab-traffic-ok_role"
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
    Name           = "dlq-lab-traffic-ok_role"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-consumer_st_dlq-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-consumer_st_dlq-lab.arn
  role       = aws_iam_role.dlq-lab-consumer_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-legacy-notifier_st_dlq-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-legacy-notifier_st_dlq-lab.arn
  role       = aws_iam_role.dlq-lab-legacy-notifier_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-notifier_st_dlq-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-notifier_st_dlq-lab.arn
  role       = aws_iam_role.dlq-lab-notifier_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_dlq-lab-producer_st_dlq-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_dlq-lab-producer_st_dlq-lab.arn
  role       = aws_iam_role.dlq-lab-producer_role.name
}

resource "aws_iam_role_policy_attachment" "scheduler_schedule_dlq-lab-traffic-ok_st_dlq-lab_attach" {
  policy_arn = aws_iam_policy.scheduler_schedule_dlq-lab-traffic-ok_st_dlq-lab.arn
  role       = aws_iam_role.dlq-lab-traffic-ok_role.name
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_event_source_mapping" "dlq-lab-orders-esm" {
  function_name                      = aws_lambda_function.dlq-lab-consumer.arn
  batch_size                         = 10
  event_source_arn                   = aws_sqs_queue.dlq-lab-orders-queue.arn
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 5
  tags = {
    Name           = "dlq-lab-orders-esm"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_struct8-templates_dlq-lab-consumer" {
  output_path = "${path.module}/struct8-templates_dlq-lab-consumer.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/sqs-sns-dlq-lab/v1/lambda/consumer"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-consumer" {
  function_name                  = "dlq-lab-consumer"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_dlq-lab-consumer.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-consumer_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_dlq-lab-consumer.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME    = "dlq-lab-consumer"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "dlq-lab-consumer"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-consumer_st_dlq-lab_attach]
}

data "archive_file" "archive_struct8-templates_dlq-lab-legacy-notifier" {
  output_path = "${path.module}/struct8-templates_dlq-lab-legacy-notifier.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/sqs-sns-dlq-lab/v1/lambda/consumer"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-legacy-notifier" {
  function_name                  = "dlq-lab-legacy-notifier"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_dlq-lab-legacy-notifier.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-legacy-notifier_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_dlq-lab-legacy-notifier.output_base64sha256
  timeout                        = 10
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq-lab-legacy-dlq.arn
  }
  environment {
    variables = {
    NAME                 = "dlq-lab-legacy-notifier"
    REGION               = data.aws_region.current.region
    ACCOUNT              = data.aws_caller_identity.current.account_id
    AWS_SQS_QUEUE_NAME_0 = "dlq-lab-legacy-dlq"
  }
  }
  tags = {
    Name           = "dlq-lab-legacy-notifier"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-legacy-notifier_st_dlq-lab_attach]
}

data "archive_file" "archive_struct8-templates_dlq-lab-notifier" {
  output_path = "${path.module}/struct8-templates_dlq-lab-notifier.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/sqs-sns-dlq-lab/v1/lambda/consumer"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-notifier" {
  function_name                  = "dlq-lab-notifier"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_dlq-lab-notifier.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-notifier_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_dlq-lab-notifier.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                                           = "dlq-lab-notifier"
    REGION                                         = data.aws_region.current.region
    ACCOUNT                                        = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_EVENT_INVOKE_CONFIG_NAME_0 = "dlq-lab-notifier-async"
  }
  }
  tags = {
    Name           = "dlq-lab-notifier"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-notifier_st_dlq-lab_attach]
}

data "archive_file" "archive_struct8-templates_dlq-lab-producer" {
  output_path = "${path.module}/struct8-templates_dlq-lab-producer.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/sqs-sns-dlq-lab/v1/lambda/producer"
  type        = "zip"
}

resource "aws_lambda_function" "dlq-lab-producer" {
  function_name                  = "dlq-lab-producer"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_dlq-lab-producer.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.dlq-lab-producer_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_dlq-lab-producer.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                           = "dlq-lab-producer"
    REGION                         = data.aws_region.current.region
    ACCOUNT                        = data.aws_caller_identity.current.account_id
    AWS_SNS_TOPIC_NAME_0           = "dlq-lab-orders"
    AWS_SQS_QUEUE_NAME_0           = "dlq-lab-orders-queue"
    AWS_LAMBDA_FUNCTION_URL_NAME_0 = "dlq-lab-producer-url"
  }
  }
  tags = {
    Name           = "dlq-lab-producer"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_dlq-lab-producer_st_dlq-lab_attach]
}

resource "aws_lambda_function_event_invoke_config" "dlq-lab-notifier-async" {
  function_name                = aws_lambda_function.dlq-lab-notifier.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
  destination_config {
    on_failure {
      destination = aws_sqs_queue.dlq-lab-notifier-failed.arn
    }
  }
}

resource "aws_lambda_function_url" "dlq-lab-producer-url" {
  function_name      = aws_lambda_function.dlq-lab-producer.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_dlq-lab-producer-url_to_dlq-lab-producer" {
  function_name          = aws_lambda_function.dlq-lab-producer.function_name
  statement_id           = "perm_aws_lambda_function_url_dlq-lab-producer-url_to_dlq-lab-producer"
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_dlq-lab-producer-url_to_dlq-lab-producer_invoke" {
  function_name            = aws_lambda_function.dlq-lab-producer.function_name
  statement_id             = "perm_aws_lambda_function_url_dlq-lab-producer-url_to_dlq-lab-producer_invoke"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
}

resource "aws_lambda_permission" "perm_aws_sns_topic_dlq-lab-orders_to_dlq-lab-legacy-notifier" {
  function_name = aws_lambda_function.dlq-lab-legacy-notifier.function_name
  statement_id  = "perm_aws_sns_topic_dlq-lab-orders_to_dlq-lab-legacy-notifier"
  principal     = "sns.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_sns_topic.dlq-lab-orders.arn
}

resource "aws_lambda_permission" "perm_aws_sns_topic_dlq-lab-orders_to_dlq-lab-notifier" {
  function_name = aws_lambda_function.dlq-lab-notifier.function_name
  statement_id  = "perm_aws_sns_topic_dlq-lab-orders_to_dlq-lab-notifier"
  principal     = "sns.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_sns_topic.dlq-lab-orders.arn
}




### CATEGORY: INTEGRATION ###

resource "aws_sqs_queue" "dlq-lab-legacy-dlq" {
  name                              = "dlq-lab-legacy-dlq"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "dlq-lab-legacy-dlq"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "dlq-lab-notifier-failed" {
  name                              = "dlq-lab-notifier-failed"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "dlq-lab-notifier-failed"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "dlq-lab-orders-dlq" {
  name                              = "dlq-lab-orders-dlq"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 1209600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "dlq-lab-orders-dlq"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "dlq-lab-orders-queue" {
  name                              = "dlq-lab-orders-queue"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 60
  tags = {
    Name           = "dlq-lab-orders-queue"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "dlq-lab-scheduler-dlq" {
  name                              = "dlq-lab-scheduler-dlq"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "dlq-lab-scheduler-dlq"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "aws_sqs_queue_policy_dlq-lab-orders-queue_st_dlq-lab_doc" {
  statement {
    sid    = "AllowSQSActions"
    effect = "Allow"
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq-lab-orders-queue.arn]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
}

resource "aws_sqs_queue_policy" "aws_sqs_queue_policy_dlq-lab-orders-queue_st_dlq-lab" {
  policy    = data.aws_iam_policy_document.aws_sqs_queue_policy_dlq-lab-orders-queue_st_dlq-lab_doc.json
  queue_url = aws_sqs_queue.dlq-lab-orders-queue.id
}

resource "aws_sns_topic" "dlq-lab-alerts" {
  name = "dlq-lab-alerts"
  tags = {
    Name           = "dlq-lab-alerts"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sns_topic" "dlq-lab-orders" {
  name = "dlq-lab-orders"
  tags = {
    Name           = "dlq-lab-orders"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_sqs_queue_policy.aws_sqs_queue_policy_dlq-lab-orders-queue_st_dlq-lab]
}

resource "aws_sns_topic_subscription" "Subscription2" {
  endpoint   = aws_lambda_function.dlq-lab-notifier.arn
  protocol   = "lambda"
  topic_arn  = aws_sns_topic.dlq-lab-orders.arn
  depends_on = [aws_lambda_permission.perm_aws_sns_topic_dlq-lab-orders_to_dlq-lab-notifier]
}

resource "aws_sns_topic_subscription" "Subscription3" {
  endpoint   = aws_lambda_function.dlq-lab-legacy-notifier.arn
  protocol   = "lambda"
  topic_arn  = aws_sns_topic.dlq-lab-orders.arn
  depends_on = [aws_lambda_permission.perm_aws_sns_topic_dlq-lab-orders_to_dlq-lab-legacy-notifier]
}

resource "aws_sns_topic_subscription" "Subscription4" {
  endpoint  = aws_sqs_queue.dlq-lab-orders-queue.arn
  protocol  = "sqs"
  topic_arn = aws_sns_topic.dlq-lab-orders.arn
}

resource "aws_scheduler_schedule" "dlq-lab-traffic-ok" {
  name                = "dlq-lab-traffic-ok"
  schedule_expression = "rate(1 minute)"
  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_sns_topic.dlq-lab-orders.arn
    input    = "{\"behavior\":\"ok\"}"
    role_arn = aws_iam_role.dlq-lab-traffic-ok_role.arn
    dead_letter_config {
      arn = aws_sqs_queue.dlq-lab-scheduler-dlq.arn
    }
    retry_policy {
      maximum_event_age_in_seconds = 60
      maximum_retry_attempts       = 0
    }
  }
  depends_on = [aws_iam_role_policy_attachment.scheduler_schedule_dlq-lab-traffic-ok_st_dlq-lab_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "dlq-lab-consumer-logs" {
  name              = "/aws/lambda/dlq-lab-consumer"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-consumer-logs"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "dlq-lab-legacy-notifier-logs" {
  name              = "/aws/lambda/dlq-lab-legacy-notifier"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-legacy-notifier-logs"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "dlq-lab-notifier-logs" {
  name              = "/aws/lambda/dlq-lab-notifier"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-notifier-logs"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "dlq-lab-producer-logs" {
  name              = "/aws/lambda/dlq-lab-producer"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "dlq-lab-producer-logs"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq-lab-orders-dlq-not-empty" {
  alarm_name          = "dlq-lab-orders-dlq-not-empty"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  alarm_actions       = [aws_sns_topic.dlq-lab-alerts.arn]
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  dimensions = {
    QueueName = aws_sqs_queue.dlq-lab-orders-dlq.name
  }
  tags = {
    Name           = "dlq-lab-orders-dlq-not-empty"
    State          = "dlq-lab"
    Struct8Creator = "Contato Struct"
  }
}


