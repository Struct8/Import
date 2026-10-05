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
    key     = "952133486861/bedrock-agent-lab/main.tfstate"
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

data "aws_iam_policy_document" "lambda_function_agent-lab-chat_st_bedrock-agent-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.agent-lab-chat-logs.arn}:*"]
  }
  statement {
    sid       = "AllowKMSAccess"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.agent-lab-key.arn]
  }
}

resource "aws_iam_policy" "lambda_function_agent-lab-chat_st_bedrock-agent-lab" {
  name        = "lambda_function_agent-lab-chat_st_bedrock-agent-lab"
  description = "Access Policy for agent-lab-chat"
  policy      = data.aws_iam_policy_document.lambda_function_agent-lab-chat_st_bedrock-agent-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.agent-lab-orders-tool-logs.arn}:*"]
  }
  statement {
    sid       = "ReadOrders"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.agent-lab-orders.arn]
  }
}

resource "aws_iam_policy" "lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab" {
  name        = "lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab"
  description = "Access Policy for agent-lab-orders-tool"
  policy      = data.aws_iam_policy_document.lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab_doc.json
}

resource "aws_iam_role" "agent-lab-chat_role" {
  name = "agent-lab-chat_role"
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
  inline_policy {
    name = "agent-lab-chat-invoke-agent"
    policy = <<EOF
{"Version":"2012-10-17","Statement":[{"Sid":"InvokeTheAgentAlias","Effect":"Allow","Action":"bedrock:InvokeAgent","Resource":"${aws_bedrockagent_agent_alias.live.agent_alias_arn}"}]}
  EOF
  }
  tags = {
    Name           = "agent-lab-chat_role"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "agent-lab-orders-tool_role" {
  name = "agent-lab-orders-tool_role"
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
    Name           = "agent-lab-orders-tool_role"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "agent-lab-orders_role" {
  name = "agent-lab-orders_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  inline_policy {
    name = "agent-lab-orders-permissions"
    policy = <<EOF
{"Version":"2012-10-17","Statement":[{"Sid":"InvokeTheModel","Effect":"Allow","Action":["bedrock:InvokeModel","bedrock:InvokeModelWithResponseStream"],"Resource":"arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.nova-lite-v1:0"},{"Sid":"ApplyTheGuardrail","Effect":"Allow","Action":"bedrock:ApplyGuardrail","Resource":"${aws_bedrock_guardrail.agent-lab-guardrail.guardrail_arn}"},{"Sid":"UseTheAgentKey","Effect":"Allow","Action":["kms:GenerateDataKey","kms:Decrypt"],"Resource":"${aws_kms_key.agent-lab-key.arn}"}]}
  EOF
  }
  tags = {
    Name           = "agent-lab-orders_role"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_agent-lab-chat_st_bedrock-agent-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_agent-lab-chat_st_bedrock-agent-lab.arn
  role       = aws_iam_role.agent-lab-chat_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab.arn
  role       = aws_iam_role.agent-lab-orders-tool_role.name
}

resource "aws_kms_key" "agent-lab-key" {
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
    Name           = "agent-lab-key"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_table" "agent-lab-orders" {
  name                        = "agent-lab-orders"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "order_id"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "order_id"
    type = "S"
  }
  tags = {
    Name           = "agent-lab-orders"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table_item" "order-1001" {
  table_name = aws_dynamodb_table.agent-lab-orders.name
  hash_key   = aws_dynamodb_table.agent-lab-orders.hash_key
  item       = "{\"order_id\":{\"S\":\"1001\"},\"status\":{\"S\":\"SHIPPED\"},\"items\":{\"S\":\"2 coffee mugs\"},\"eta\":{\"S\":\"2026-10-08\"}}"
  range_key  = aws_dynamodb_table.agent-lab-orders.range_key
}

resource "aws_dynamodb_table_item" "order-1002" {
  table_name = aws_dynamodb_table.agent-lab-orders.name
  hash_key   = aws_dynamodb_table.agent-lab-orders.hash_key
  item       = "{\"order_id\":{\"S\":\"1002\"},\"status\":{\"S\":\"PROCESSING\"},\"items\":{\"S\":\"1 desk lamp\"},\"eta\":{\"S\":\"2026-10-12\"}}"
  range_key  = aws_dynamodb_table.agent-lab-orders.range_key
}

resource "aws_dynamodb_table_item" "order-1003" {
  table_name = aws_dynamodb_table.agent-lab-orders.name
  hash_key   = aws_dynamodb_table.agent-lab-orders.hash_key
  item       = "{\"order_id\":{\"S\":\"1003\"},\"status\":{\"S\":\"DELIVERED\"},\"items\":{\"S\":\"3 notebooks\"},\"delivered_on\":{\"S\":\"2026-10-01\"}}"
  range_key  = aws_dynamodb_table.agent-lab-orders.range_key
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-templates_agent-lab-chat" {
  output_path = "${path.module}/struct8-templates_agent-lab-chat.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/bedrock-agent-lab/v1/lambda/chat"
  type        = "zip"
}

resource "aws_lambda_function" "agent-lab-chat" {
  function_name                  = "agent-lab-chat"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_agent-lab-chat.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.agent-lab-chat_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_agent-lab-chat.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
    AGENT_ID                       = aws_bedrockagent_agent.agent-lab-orders.agent_id
    AGENT_ALIAS_ID                 = aws_bedrockagent_agent_alias.live.agent_alias_id
    NAME                           = "agent-lab-chat"
    REGION                         = data.aws_region.current.region
    ACCOUNT                        = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0 = "agent-lab-chat-url"
    AWS_KMS_KEY_NAME_0             = "agent-lab-key"
  }
  }
  tags = {
    Name           = "agent-lab-chat"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_agent-lab-chat_st_bedrock-agent-lab_attach]
}

data "archive_file" "archive_struct8-templates_agent-lab-orders-tool" {
  output_path = "${path.module}/struct8-templates_agent-lab-orders-tool.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/bedrock-agent-lab/v1/lambda/orders-tool"
  type        = "zip"
}

resource "aws_lambda_function" "agent-lab-orders-tool" {
  function_name                  = "agent-lab-orders-tool"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_agent-lab-orders-tool.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.agent-lab-orders-tool_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_agent-lab-orders-tool.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
    NAME                      = "agent-lab-orders-tool"
    REGION                    = data.aws_region.current.region
    ACCOUNT                   = data.aws_caller_identity.current.account_id
    AWS_DYNAMODB_TABLE_NAME_0 = "agent-lab-orders"
  }
  }
  tags = {
    Name           = "agent-lab-orders-tool"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab_attach]
}

resource "aws_lambda_function_url" "agent-lab-chat-url" {
  function_name      = aws_lambda_function.agent-lab-chat.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "agent-lab-chat-url-invoke" {
  function_name            = aws_lambda_function.agent-lab-chat.function_name
  statement_id             = "FunctionURLInvokeAllowPublicAccess"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
}

resource "aws_lambda_permission" "agent-lab-chat-url-public" {
  function_name            = aws_lambda_function.agent-lab-chat.function_name
  statement_id             = "FunctionURLAllowPublicAccess"
  principal                = "*"
  action                   = "lambda:InvokeFunctionUrl"
  function_url_auth_type   = "NONE"
  invoked_via_function_url = false
}

resource "aws_lambda_permission" "agent-lab-orders-tool-invoke" {
  function_name            = aws_lambda_function.agent-lab-orders-tool.function_name
  statement_id             = "AllowBedrockAgentInvoke"
  principal                = "bedrock.amazonaws.com"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = false
  source_account           = data.aws_caller_identity.current.account_id
  source_arn               = aws_bedrockagent_agent.agent-lab-orders.agent_arn
}




### CATEGORY: AI ###

resource "aws_bedrock_guardrail" "agent-lab-guardrail" {
  name                      = "agent-lab-guardrail"
  blocked_input_messaging   = "Sorry, the model cannot answer this question."
  blocked_outputs_messaging = "Sorry, the model cannot answer this question."
  content_policy_config {
    filters_config {
      input_strength  = "HIGH"
      output_strength = "NONE"
      type            = "PROMPT_ATTACK"
    }
  }
  sensitive_information_policy_config {
    pii_entities_config {
      action = "ANONYMIZE"
      type   = "EMAIL"
    }
  }
  tags = {
    Name           = "agent-lab-guardrail"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrockagent_agent" "agent-lab-orders" {
  # ajuste manual · foundation_model — The compile drops every field of this agent before the generator sees it: the type's schema.js is still in the provider's raw format (block.attributes), and the compile keeps only the fields its schemas list under inputs. foundation_model is required, so without this the plan fails.
  # ajuste manual · instruction — The compile drops every field of this agent (schema.js still in the provider's raw format), so the instruction written in the form never reaches the code.
  # ajuste manual · memory_configuration — The compile drops every field of this agent (schema.js still in the provider's raw format). In the provider this is a list-of-objects attribute, written with '=', not a block.
  # ajuste manual · guardrail_configuration — The guardrail wired to this agent writes nothing into the code, and in the provider this is a list-of-objects attribute, written with '=', not a block.
  agent_name                  = "agent-lab-orders"
  agent_resource_role_arn     = aws_iam_role.agent-lab-orders_role.arn
  customer_encryption_key_arn = aws_kms_key.agent-lab-key.arn
  foundation_model            = "amazon.nova-lite-v1:0"
  guardrail_configuration     = [{ guardrail_identifier = aws_bedrock_guardrail.agent-lab-guardrail.guardrail_id, guardrail_version = aws_bedrock_guardrail.agent-lab-guardrail.version }]
  instruction                 = "You are the order desk assistant of a small online store. When a customer asks about an order, call the get_order_status function with the order number they give, and answer with its status, items and expected delivery date. If no order number is given, ask for it. Never invent order data: if the order is not found, say so."
  memory_configuration        = [{ enabled_memory_types = ["SESSION_SUMMARY"], storage_days = 30, session_summary_configuration = [{ max_recent_sessions = 20 }] }]
}

resource "aws_bedrockagent_agent_action_group" "orders" {
  action_group_name          = "orders"
  agent_id                   = aws_bedrockagent_agent.agent-lab-orders.agent_id
  agent_version              = "DRAFT"
  prepare_agent              = true
  skip_resource_in_use_check = true
  action_group_executor {
    lambda = aws_lambda_function.agent-lab-orders-tool.arn
  }
  function_schema {
    member_functions {
      functions {
        name        = "get_order_status"
        description = "Returns the status, items and delivery date of one order."
        parameters {
          description   = "The order number, for example 1001."
          map_block_key = "order_id"
          required      = true
          type          = "string"
        }
      }
    }
  }
}

resource "aws_bedrockagent_agent_alias" "live" {
  # ajuste manual · depends_on — Bedrock builds the alias's version from the prepared draft at the moment the alias is created. Nothing orders the alias after the action group, an uncurated node it does not reference, so it could serve a version without the get_order_status tool.
  agent_alias_name = "live"
  agent_id         = aws_bedrockagent_agent.agent-lab-orders.agent_id
  description      = "Version served to the chat function"
  tags = {
    Name           = "live"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_bedrockagent_agent_action_group.orders]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "agent-lab-chat-logs" {
  name              = "/aws/lambda/agent-lab-chat"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "agent-lab-chat-logs"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "agent-lab-orders-tool-logs" {
  name              = "/aws/lambda/agent-lab-orders-tool"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "agent-lab-orders-tool-logs"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}


