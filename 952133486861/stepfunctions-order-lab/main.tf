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
    key     = "952133486861/stepfunctions-order-lab/main.tfstate"
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

data "aws_iam_policy_document" "lambda_function_order-approval-inbox_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-approval-inbox-logs.arn}:*"]
  }
  statement {
    sid       = "AllowDynamoDBCRUD"
    effect    = "Allow"
    actions   = ["dynamodb:BatchGetItem", "dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.order-lab-data.arn, "${aws_dynamodb_table.order-lab-data.arn}/*"]
  }
  statement {
    sid       = "AllowEventSourceRead"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
    resources = [aws_sqs_queue.order-approvals.arn]
  }
}

resource "aws_iam_policy" "lambda_function_order-approval-inbox_st_stepfunctions-order-lab" {
  name        = "lambda_function_order-approval-inbox_st_stepfunctions-order-lab"
  description = "Access Policy for order-approval-inbox"
  policy      = data.aws_iam_policy_document.lambda_function_order-approval-inbox_st_stepfunctions-order-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_order-charge_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-charge-logs.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_function_order-charge_st_stepfunctions-order-lab" {
  name        = "lambda_function_order-charge_st_stepfunctions-order-lab"
  description = "Access Policy for order-charge"
  policy      = data.aws_iam_policy_document.lambda_function_order-charge_st_stepfunctions-order-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_order-console_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-console-logs.arn}:*"]
  }
  statement {
    sid       = "AllowDynamoDBCRUD"
    effect    = "Allow"
    actions   = ["dynamodb:BatchGetItem", "dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.order-lab-data.arn, "${aws_dynamodb_table.order-lab-data.arn}/*"]
  }
  statement {
    sid       = "AllowStartExecution"
    effect    = "Allow"
    actions   = ["states:StartExecution", "states:StartSyncExecution"]
    resources = [aws_sfn_state_machine.order-workflow.arn]
  }
  statement {
    sid       = "AllowSQSActions"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.order-notifications.arn]
  }
  statement {
    sid       = "AllowCompleteCallbackTasks"
    effect    = "Allow"
    actions   = ["states:SendTaskFailure", "states:SendTaskHeartbeat", "states:SendTaskSuccess"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowFollowExecutions"
    effect    = "Allow"
    actions   = ["states:DescribeExecution", "states:GetExecutionHistory", "states:StopExecution"]
    resources = ["arn:aws:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:execution:${aws_sfn_state_machine.order-workflow.name}:*"]
  }
}

resource "aws_iam_policy" "lambda_function_order-console_st_stepfunctions-order-lab" {
  name        = "lambda_function_order-console_st_stepfunctions-order-lab"
  description = "Access Policy for order-console"
  policy      = data.aws_iam_policy_document.lambda_function_order-console_st_stepfunctions-order-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_order-pack-item_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-pack-item-logs.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_function_order-pack-item_st_stepfunctions-order-lab" {
  name        = "lambda_function_order-pack-item_st_stepfunctions-order-lab"
  description = "Access Policy for order-pack-item"
  policy      = data.aws_iam_policy_document.lambda_function_order-pack-item_st_stepfunctions-order-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_order-release_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-release-logs.arn}:*"]
  }
  statement {
    sid       = "AllowDynamoDBCRUD"
    effect    = "Allow"
    actions   = ["dynamodb:BatchGetItem", "dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.order-lab-data.arn, "${aws_dynamodb_table.order-lab-data.arn}/*"]
  }
}

resource "aws_iam_policy" "lambda_function_order-release_st_stepfunctions-order-lab" {
  name        = "lambda_function_order-release_st_stepfunctions-order-lab"
  description = "Access Policy for order-release"
  policy      = data.aws_iam_policy_document.lambda_function_order-release_st_stepfunctions-order-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_order-reserve_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-reserve-logs.arn}:*"]
  }
  statement {
    sid       = "AllowDynamoDBCRUD"
    effect    = "Allow"
    actions   = ["dynamodb:BatchGetItem", "dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.order-lab-data.arn, "${aws_dynamodb_table.order-lab-data.arn}/*"]
  }
}

resource "aws_iam_policy" "lambda_function_order-reserve_st_stepfunctions-order-lab" {
  name        = "lambda_function_order-reserve_st_stepfunctions-order-lab"
  description = "Access Policy for order-reserve"
  policy      = data.aws_iam_policy_document.lambda_function_order-reserve_st_stepfunctions-order-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_order-validate_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-validate-logs.arn}:*"]
  }
}

resource "aws_iam_policy" "lambda_function_order-validate_st_stepfunctions-order-lab" {
  name        = "lambda_function_order-validate_st_stepfunctions-order-lab"
  description = "Access Policy for order-validate"
  policy      = data.aws_iam_policy_document.lambda_function_order-validate_st_stepfunctions-order-lab_doc.json
}

data "aws_iam_policy_document" "sfn_state_machine_order-workflow_st_stepfunctions-order-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.order-workflow-logs.arn}:*"]
  }
  statement {
    sid       = "AllowDynamoDBCRUD"
    effect    = "Allow"
    actions   = ["dynamodb:BatchGetItem", "dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.order-lab-data.arn, "${aws_dynamodb_table.order-lab-data.arn}/*"]
  }
  statement {
    sid       = "AllowLambdaInvoke"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.order-charge.arn]
  }
  statement {
    sid       = "AllowLambdaInvoke1"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.order-pack-item.arn]
  }
  statement {
    sid       = "AllowLambdaInvoke2"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.order-release.arn]
  }
  statement {
    sid       = "AllowLambdaInvoke3"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.order-reserve.arn]
  }
  statement {
    sid       = "AllowLambdaInvoke4"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.order-validate.arn]
  }
  statement {
    sid       = "AllowSNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.order-events.arn]
  }
  statement {
    sid       = "AllowSQSActions"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
    resources = [aws_sqs_queue.order-approvals.arn]
  }
  statement {
    sid       = "DeliverExecutionLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogDelivery", "logs:CreateLogStream", "logs:DeleteLogDelivery", "logs:DescribeLogGroups", "logs:DescribeResourcePolicies", "logs:GetLogDelivery", "logs:ListLogDeliveries", "logs:PutLogEvents", "logs:PutResourcePolicy", "logs:UpdateLogDelivery", "xray:GetSamplingRules", "xray:GetSamplingTargets", "xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sfn_state_machine_order-workflow_st_stepfunctions-order-lab" {
  name        = "sfn_state_machine_order-workflow_st_stepfunctions-order-lab"
  description = "Access Policy for order-workflow"
  policy      = data.aws_iam_policy_document.sfn_state_machine_order-workflow_st_stepfunctions-order-lab_doc.json
}

resource "aws_iam_role" "order-approval-inbox_role" {
  name = "order-approval-inbox_role"
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
    Name           = "order-approval-inbox_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "order-charge_role" {
  name = "order-charge_role"
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
    Name           = "order-charge_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "order-console_role" {
  name = "order-console_role"
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
    Name           = "order-console_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "order-pack-item_role" {
  name = "order-pack-item_role"
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
    Name           = "order-pack-item_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "order-release_role" {
  name = "order-release_role"
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
    Name           = "order-release_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "order-reserve_role" {
  name = "order-reserve_role"
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
    Name           = "order-reserve_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "order-validate_role" {
  name = "order-validate_role"
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
    Name           = "order-validate_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "order-workflow_role" {
  name = "order-workflow_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "order-workflow_role"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_order-approval-inbox_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_order-approval-inbox_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-approval-inbox_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_order-charge_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_order-charge_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-charge_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_order-console_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_order-console_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-console_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_order-pack-item_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_order-pack-item_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-pack-item_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_order-release_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_order-release_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-release_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_order-reserve_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_order-reserve_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-reserve_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_order-validate_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_order-validate_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-validate_role.name
}

resource "aws_iam_role_policy_attachment" "sfn_state_machine_order-workflow_st_stepfunctions-order-lab_attach" {
  policy_arn = aws_iam_policy.sfn_state_machine_order-workflow_st_stepfunctions-order-lab.arn
  role       = aws_iam_role.order-workflow_role.name
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_table" "order-lab-data" {
  name                        = "order-lab-data"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "pk"
  range_key                   = "sk"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  tags = {
    Name           = "order-lab-data"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_event_source_mapping" "order-approvals-to-inbox" {
  function_name           = aws_lambda_function.order-approval-inbox.arn
  event_source_arn        = aws_sqs_queue.order-approvals.arn
  function_response_types = ["ReportBatchItemFailures"]
  tags = {
    Name           = "order-approvals-to-inbox"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_struct8-templates_order-approval-inbox" {
  output_path = "${path.module}/struct8-templates_order-approval-inbox.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/lambda/order-approval-inbox"
  type        = "zip"
}

resource "aws_lambda_function" "order-approval-inbox" {
  function_name                  = "order-approval-inbox"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_order-approval-inbox.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.order-approval-inbox_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_order-approval-inbox.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                      = "order-approval-inbox"
    REGION                    = data.aws_region.current.region
    ACCOUNT                   = data.aws_caller_identity.current.account_id
    AWS_DYNAMODB_TABLE_NAME_0 = "order-lab-data"
  }
  }
  tags = {
    Name           = "order-approval-inbox"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_order-approval-inbox_st_stepfunctions-order-lab_attach]
}

data "archive_file" "archive_struct8-templates_order-charge" {
  output_path = "${path.module}/struct8-templates_order-charge.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/lambda/order-charge"
  type        = "zip"
}

resource "aws_lambda_function" "order-charge" {
  function_name                  = "order-charge"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_order-charge.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.order-charge_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_order-charge.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME    = "order-charge"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "order-charge"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_order-charge_st_stepfunctions-order-lab_attach]
}

data "archive_file" "archive_struct8-templates_order-console" {
  output_path = "${path.module}/struct8-templates_order-console.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/lambda/order-console"
  type        = "zip"
}

resource "aws_lambda_function" "order-console" {
  function_name                  = "order-console"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_order-console.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.order-console_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_order-console.output_base64sha256
  timeout                        = 15
  environment {
    variables = {
    NAME                           = "order-console"
    REGION                         = data.aws_region.current.region
    ACCOUNT                        = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0 = "order-console-url"
    AWS_DYNAMODB_TABLE_NAME_0      = "order-lab-data"
    AWS_SFN_STATE_MACHINE_ARN_0    = aws_sfn_state_machine.order-workflow.arn
    AWS_SQS_QUEUE_NAME_0           = "order-notifications"
  }
  }
  tags = {
    Name           = "order-console"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_order-console_st_stepfunctions-order-lab_attach]
}

data "archive_file" "archive_struct8-templates_order-pack-item" {
  output_path = "${path.module}/struct8-templates_order-pack-item.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/lambda/order-pack-item"
  type        = "zip"
}

resource "aws_lambda_function" "order-pack-item" {
  function_name                  = "order-pack-item"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_order-pack-item.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.order-pack-item_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_order-pack-item.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME    = "order-pack-item"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "order-pack-item"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_order-pack-item_st_stepfunctions-order-lab_attach]
}

data "archive_file" "archive_struct8-templates_order-release" {
  output_path = "${path.module}/struct8-templates_order-release.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/lambda/order-release"
  type        = "zip"
}

resource "aws_lambda_function" "order-release" {
  function_name                  = "order-release"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_order-release.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.order-release_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_order-release.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                      = "order-release"
    REGION                    = data.aws_region.current.region
    ACCOUNT                   = data.aws_caller_identity.current.account_id
    AWS_DYNAMODB_TABLE_NAME_0 = "order-lab-data"
  }
  }
  tags = {
    Name           = "order-release"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_order-release_st_stepfunctions-order-lab_attach]
}

data "archive_file" "archive_struct8-templates_order-reserve" {
  output_path = "${path.module}/struct8-templates_order-reserve.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/lambda/order-reserve"
  type        = "zip"
}

resource "aws_lambda_function" "order-reserve" {
  function_name                  = "order-reserve"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_order-reserve.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.order-reserve_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_order-reserve.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                      = "order-reserve"
    REGION                    = data.aws_region.current.region
    ACCOUNT                   = data.aws_caller_identity.current.account_id
    AWS_DYNAMODB_TABLE_NAME_0 = "order-lab-data"
  }
  }
  tags = {
    Name           = "order-reserve"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_order-reserve_st_stepfunctions-order-lab_attach]
}

data "archive_file" "archive_struct8-templates_order-validate" {
  output_path = "${path.module}/struct8-templates_order-validate.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/lambda/order-validate"
  type        = "zip"
}

resource "aws_lambda_function" "order-validate" {
  function_name                  = "order-validate"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_order-validate.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.order-validate_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_order-validate.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME    = "order-validate"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "order-validate"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_order-validate_st_stepfunctions-order-lab_attach]
}

resource "aws_lambda_function_url" "order-console-url" {
  function_name      = aws_lambda_function.order-console.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_order-console-url_to_order-console" {
  function_name          = aws_lambda_function.order-console.function_name
  statement_id           = "perm_aws_lambda_function_url_order-console-url_to_order-console"
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_order-console-url_to_order-console_invoke" {
  function_name            = aws_lambda_function.order-console.function_name
  statement_id             = "perm_aws_lambda_function_url_order-console-url_to_order-console_invoke"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
}




### CATEGORY: INTEGRATION ###

resource "aws_sqs_queue" "order-approvals" {
  name                              = "order-approvals"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "order-approvals"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_sqs_queue" "order-notifications" {
  name                              = "order-notifications"
  delay_seconds                     = 0
  fifo_queue                        = false
  kms_data_key_reuse_period_seconds = 300
  max_message_size                  = 262144
  message_retention_seconds         = 86400
  receive_wait_time_seconds         = 0
  sqs_managed_sse_enabled           = true
  visibility_timeout_seconds        = 30
  tags = {
    Name           = "order-notifications"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "aws_sqs_queue_policy_order-notifications_st_stepfunctions-order-lab_doc" {
  statement {
    sid    = "AllowSQSActions"
    effect = "Allow"
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.order-notifications.arn]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
}

resource "aws_sqs_queue_policy" "aws_sqs_queue_policy_order-notifications_st_stepfunctions-order-lab" {
  policy    = data.aws_iam_policy_document.aws_sqs_queue_policy_order-notifications_st_stepfunctions-order-lab_doc.json
  queue_url = aws_sqs_queue.order-notifications.id
}

resource "aws_sns_topic" "order-events" {
  name = "order-events"
  tags = {
    Name           = "order-events"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_sqs_queue_policy.aws_sqs_queue_policy_order-notifications_st_stepfunctions-order-lab]
}

data "aws_iam_policy_document" "aws_sns_topic_policy_order-events_st_stepfunctions-order-lab_doc" {
  statement {
    sid    = "AllowCloudWatchAlarmsToPublish"
    effect = "Allow"
    principals {
      identifiers = ["cloudwatch.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.order-events.arn]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
  statement {
    sid    = "AllowEventBridgeToPublishToSNS"
    effect = "Allow"
    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.order-events.arn]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "AWS:SourceAccount"
    }
  }
}

resource "aws_sns_topic_policy" "aws_sns_topic_policy_order-events_st_stepfunctions-order-lab" {
  arn    = aws_sns_topic.order-events.arn
  policy = data.aws_iam_policy_document.aws_sns_topic_policy_order-events_st_stepfunctions-order-lab_doc.json
}

resource "aws_sns_topic_subscription" "Subscription5" {
  endpoint  = aws_sqs_queue.order-notifications.arn
  protocol  = "sqs"
  topic_arn = aws_sns_topic.order-events.arn
}

resource "aws_cloudwatch_event_rule" "order-failure-alerts" {
  name        = "order-failure-alerts"
  description = "Executions of order-workflow that end FAILED, TIMED_OUT or ABORTED."
  event_pattern = <<EOF
{
  "source": ["aws.states"],
  "detail-type": ["Step Functions Execution Status Change"],
  "detail": {
    "status": ["FAILED", "TIMED_OUT", "ABORTED"],
    "stateMachineArn": ["${aws_sfn_state_machine.order-workflow.arn}"]
  }
}
  EOF
  state = "ENABLED"
  tags = {
    Name           = "order-failure-alerts"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_sns_topic_policy.aws_sns_topic_policy_order-events_st_stepfunctions-order-lab]
}

resource "aws_cloudwatch_event_target" "Target4" {
  arn  = aws_sns_topic.order-events.arn
  rule = aws_cloudwatch_event_rule.order-failure-alerts.name
}

resource "aws_sfn_state_machine" "order-workflow" {
  name = "order-workflow"
  definition = templatefile("${path.module}/.external_modules/struct8-templates/templates/stepfunctions-order-lab/v1/stepfunctions/order-workflow.asl.json", {
    aws_cloudwatch_log_group = {
      "order-workflow-logs" = aws_cloudwatch_log_group.order-workflow-logs
    }
    aws_dynamodb_table = {
      "order-lab-data" = aws_dynamodb_table.order-lab-data
    }
    aws_lambda_function = {
      "order-charge"    = aws_lambda_function.order-charge
      "order-pack-item" = aws_lambda_function.order-pack-item
      "order-release"   = aws_lambda_function.order-release
      "order-reserve"   = aws_lambda_function.order-reserve
      "order-validate"  = aws_lambda_function.order-validate
    }
    aws_sns_topic = {
      "order-events" = aws_sns_topic.order-events
    }
    aws_sqs_queue = {
      "order-approvals" = aws_sqs_queue.order-approvals
    }
  })
  role_arn = aws_iam_role.order-workflow_role.arn
  logging_configuration {
    include_execution_data = true
    level                  = "ALL"
    log_destination        = "${aws_cloudwatch_log_group.order-workflow-logs.arn}:*"
  }
  tags = {
    Name           = "order-workflow"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  tracing_configuration {
    enabled = true
  }
  depends_on = [aws_iam_role_policy_attachment.sfn_state_machine_order-workflow_st_stepfunctions-order-lab_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "order-approval-inbox-logs" {
  name              = "/aws/lambda/order-approval-inbox"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-approval-inbox-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "order-charge-logs" {
  name              = "/aws/lambda/order-charge"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-charge-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "order-console-logs" {
  name              = "/aws/lambda/order-console"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-console-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "order-pack-item-logs" {
  name              = "/aws/lambda/order-pack-item"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-pack-item-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "order-release-logs" {
  name              = "/aws/lambda/order-release"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-release-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "order-reserve-logs" {
  name              = "/aws/lambda/order-reserve"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-reserve-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "order-validate-logs" {
  name              = "/aws/lambda/order-validate"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-validate-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "order-workflow-logs" {
  name              = "/aws/vendedlogs/states/order-workflow"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "order-workflow-logs"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "order-executions-failed" {
  alarm_name          = "order-executions-failed"
  metric_name         = "ExecutionsFailed"
  alarm_actions       = [aws_sns_topic.order-events.arn]
  alarm_description   = "At least one execution of order-workflow failed in the last minute."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  dimensions = {
    StateMachineArn = aws_sfn_state_machine.order-workflow.arn
  }
  tags = {
    Name           = "order-executions-failed"
    State          = "stepfunctions-order-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_sns_topic_policy.aws_sns_topic_policy_order-events_st_stepfunctions-order-lab]
}


