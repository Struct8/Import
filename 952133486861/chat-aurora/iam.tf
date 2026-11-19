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
