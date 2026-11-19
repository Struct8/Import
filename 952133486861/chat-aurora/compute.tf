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
  reserved_concurrent_executions = -1
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
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
  statement_id_prefix    = "perm_aws_lambda_function_url_FuncUrl_to_web_chat"
  depends_on             = [aws_lambda_function_url.FuncUrl]
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_FuncUrl_to_web_chat_invoke" {
  function_name            = aws_lambda_function.web_chat.function_name
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
  statement_id_prefix      = "perm_aws_lambda_function_url_FuncUrl_to_web_chat_invoke"
  depends_on               = [aws_lambda_function_url.FuncUrl, aws_lambda_permission.perm_aws_lambda_function_url_FuncUrl_to_web_chat]
}

resource "aws_lambda_permission" "perm_aws_lambda_function_web_chat_to_db_query" {
  function_name       = aws_lambda_function.db_query.function_name
  principal           = "lambda.amazonaws.com"
  action              = "lambda:InvokeFunction"
  source_arn          = aws_lambda_function.web_chat.arn
  statement_id_prefix = "perm_aws_lambda_function_web_chat_to_db_query"
}
