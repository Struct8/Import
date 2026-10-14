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
    key     = "952133486861/chat-aurora/main.tfstate"
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

data "aws_rds_cluster" "wp-aurora" {
  cluster_identifier = "wp-aurora"
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "lambda_function_db_query_st_chat-aurora_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.LogGroup.arn}:*"]
  }
  statement {
    sid       = "AllowRDSDataApiwpaurora"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [data.aws_rds_cluster.wp-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccesswpaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [data.aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "lambda_function_db_query_st_chat-aurora" {
  name        = "lambda_function_db_query_st_chat-aurora"
  description = "Access Policy for db_query"
  policy      = data.aws_iam_policy_document.lambda_function_db_query_st_chat-aurora_doc.json
}

data "aws_iam_policy_document" "lambda_function_web_chat_st_chat-aurora_doc" {
  statement {
    sid       = "AllowInvokeInferenceProfile"
    effect    = "Allow"
    actions   = ["bedrock:GetInferenceProfile", "bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = [aws_bedrock_inference_profile.bedrock_devstral.arn]
  }
  statement {
    sid       = "AllowInvokeInferenceProfile1"
    effect    = "Allow"
    actions   = ["bedrock:GetInferenceProfile", "bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = [aws_bedrock_inference_profile.bedrock_haiku.arn]
  }
  statement {
    sid       = "AllowInvokeInferenceProfile2"
    effect    = "Allow"
    actions   = ["bedrock:GetInferenceProfile", "bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = [aws_bedrock_inference_profile.bedrock_nova_2_lite.arn]
  }
  statement {
    sid       = "AllowInvokeInferenceProfile3"
    effect    = "Allow"
    actions   = ["bedrock:GetInferenceProfile", "bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = [aws_bedrock_inference_profile.bedrock_nova_micro.arn]
  }
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.web_chat_logs.arn}:*"]
  }
  statement {
    sid       = "AllowDynamoDBCRUD"
    effect    = "Allow"
    actions   = ["dynamodb:BatchGetItem", "dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.chat_budget.arn, "${aws_dynamodb_table.chat_budget.arn}/*"]
  }
  statement {
    sid       = "AllowLambdaInvoke"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.db_query.arn]
  }
  statement {
    sid       = "AllowInferenceProfileModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.amazon.nova-2-lite-v1:0", "arn:aws:bedrock:*::foundation-model/amazon.nova-2-lite-v1:0"]
  }
  statement {
    sid       = "AllowInferenceProfileModel1"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.amazon.nova-micro-v1:0", "arn:aws:bedrock:*::foundation-model/amazon.nova-micro-v1:0"]
  }
  statement {
    sid       = "AllowInferenceProfileModel2"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-5-5", "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-5-5"]
  }
  statement {
    sid       = "AllowInferenceProfileModel3"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/mistral.devstral-2-123b"]
  }
}

resource "aws_iam_policy" "lambda_function_web_chat_st_chat-aurora" {
  name        = "lambda_function_web_chat_st_chat-aurora"
  description = "Access Policy for web_chat"
  policy      = data.aws_iam_policy_document.lambda_function_web_chat_st_chat-aurora_doc.json
}

resource "aws_iam_role" "db_query_role" {
  name = "db_query_role"
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
    Name           = "db_query_role"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "web_chat_role" {
  name = "web_chat_role"
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
    Name           = "web_chat_role"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_db_query_st_chat-aurora_attach" {
  policy_arn = aws_iam_policy.lambda_function_db_query_st_chat-aurora.arn
  role       = aws_iam_role.db_query_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_web_chat_st_chat-aurora_attach" {
  policy_arn = aws_iam_policy.lambda_function_web_chat_st_chat-aurora.arn
  role       = aws_iam_role.web_chat_role.name
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_table" "chat_budget" {
  name                        = "chat_budget"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "pk"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "pk"
    type = "S"
  }
  tags = {
    Name           = "chat_budget"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-templates_db_query" {
  output_path = "${path.module}/struct8-templates_db_query.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/lambda/db-query"
  type        = "zip"
}

resource "aws_lambda_function" "db_query" {
  function_name                  = "db_query"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_db_query.output_path
  handler                        = "index.handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.db_query_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-templates_db_query.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "db_query"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = data.aws_rds_cluster.wp-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = data.aws_rds_cluster.wp-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = data.aws_rds_cluster.wp-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = data.aws_rds_cluster.wp-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = data.aws_rds_cluster.wp-aurora.database_name
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(data.aws_rds_cluster.wp-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = data.aws_rds_cluster.wp-aurora.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "db_query"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_db_query_st_chat-aurora_attach]
}

data "archive_file" "archive_struct8-templates_web_chat" {
  output_path = "${path.module}/struct8-templates_web_chat.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/lambda/web-chat"
  type        = "zip"
}

resource "aws_lambda_function" "web_chat" {
  function_name                  = "web_chat"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_web_chat.output_path
  handler                        = "index.handler"
  memory_size                    = 512
  publish                        = false
  reserved_concurrent_executions = 2
  role                           = aws_iam_role.web_chat_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-templates_web_chat.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    DAILY_BUDGET_USD                     = "5"
    MAX_OUTPUT_TOKENS                    = "1024"
    MAX_TOOL_CALLS                       = "4"
    MAX_HISTORY_TURNS                    = "10"
    MODEL_ROWS                           = "50"
    PRICE_TABLE                          = "{\"M1\":{\"input_per_1k\":0.00033,\"output_per_1k\":0.00275},\"M2\":{\"input_per_1k\":0.000035,\"output_per_1k\":0.00014},\"M3\":{\"input_per_1k\":0.00011,\"output_per_1k\":0.00055},\"M4\":{\"input_per_1k\":0.0004,\"output_per_1k\":0.002}}"
    NAME                                 = "web_chat"
    REGION                               = data.aws_region.current.region
    ACCOUNT                              = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0       = "FuncUrl"
    AWS_LAMBDA_FUNCTION_NAME_0           = "db_query"
    AWS_DYNAMODB_TABLE_NAME_0            = "chat_budget"
    AWS_BEDROCK_INFERENCE_PROFILE_ARN_M3 = aws_bedrock_inference_profile.bedrock_haiku.arn
    AWS_BEDROCK_INFERENCE_PROFILE_ARN_M2 = aws_bedrock_inference_profile.bedrock_nova_micro.arn
    AWS_BEDROCK_INFERENCE_PROFILE_ARN_M1 = aws_bedrock_inference_profile.bedrock_nova_2_lite.arn
    AWS_BEDROCK_INFERENCE_PROFILE_ARN_M4 = aws_bedrock_inference_profile.bedrock_devstral.arn
  }
  }
  tags = {
    Name           = "web_chat"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_web_chat_st_chat-aurora_attach]
}

resource "aws_lambda_function_url" "FuncUrl" {
  function_name      = aws_lambda_function.web_chat.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_FuncUrl_to_web_chat" {
  function_name          = aws_lambda_function.web_chat.function_name
  statement_id           = "perm_aws_lambda_function_url_FuncUrl_to_web_chat"
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_FuncUrl_to_web_chat_invoke" {
  function_name            = aws_lambda_function.web_chat.function_name
  statement_id             = "perm_aws_lambda_function_url_FuncUrl_to_web_chat_invoke"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
}

resource "aws_lambda_permission" "perm_aws_lambda_function_web_chat_to_db_query" {
  function_name = aws_lambda_function.db_query.function_name
  statement_id  = "perm_aws_lambda_function_web_chat_to_db_query"
  principal     = "lambda.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_lambda_function.web_chat.arn
}




### CATEGORY: AI ###

resource "aws_bedrock_inference_profile" "bedrock_devstral" {
  name = "bedrock_devstral"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/mistral.devstral-2-123b"
  }
  tags = {
    Name           = "bedrock_devstral"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrock_inference_profile" "bedrock_haiku" {
  name = "bedrock_haiku"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-5-5"
  }
  tags = {
    Name           = "bedrock_haiku"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrock_inference_profile" "bedrock_nova_2_lite" {
  name = "bedrock_nova_2_lite"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.amazon.nova-2-lite-v1:0"
  }
  tags = {
    Name           = "bedrock_nova_2_lite"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrock_inference_profile" "bedrock_nova_micro" {
  name = "bedrock_nova_micro"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.amazon.nova-micro-v1:0"
  }
  tags = {
    Name           = "bedrock_nova_micro"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "LogGroup" {
  name              = "/aws/lambda/db_query"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "LogGroup"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "web_chat_logs" {
  name              = "/aws/lambda/web_chat"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "web_chat_logs"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}


