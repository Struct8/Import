terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
    time = {
      source = "hashicorp/time"
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

data "aws_iam_policy_document" "bedrockagentcore_gateway_agent-lab-gateway_st_bedrock-agent-lab_doc" {
  statement {
    sid       = "InvokeTheTargetFunction"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.agent-lab-orders-tool.arn]
  }
}

resource "aws_iam_policy" "bedrockagentcore_gateway_agent-lab-gateway_st_bedrock-agent-lab" {
  name        = "bedrockagentcore_gateway_agent-lab-gateway_st_bedrock-agent-lab"
  description = "Access Policy for agent-lab-gateway"
  policy      = data.aws_iam_policy_document.bedrockagentcore_gateway_agent-lab-gateway_st_bedrock-agent-lab_doc.json
}

data "aws_iam_policy_document" "bedrockagentcore_harness_agent_lab_orders_st_bedrock-agent-lab_doc" {
  statement {
    sid       = "AgentCoreGatewayAccess"
    effect    = "Allow"
    actions   = ["bedrock-agentcore:InvokeGateway"]
    resources = [aws_bedrockagentcore_gateway.agent-lab-gateway.gateway_arn]
  }
  statement {
    sid       = "AgentCoreMemory"
    effect    = "Allow"
    actions   = ["bedrock-agentcore:CreateEvent", "bedrock-agentcore:DeleteEvent", "bedrock-agentcore:GetEvent", "bedrock-agentcore:ListEvents", "bedrock-agentcore:RetrieveMemoryRecords"]
    resources = [aws_bedrockagentcore_memory.agent_lab_memory.arn]
  }
  statement {
    sid       = "AgentCoreMemoryKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:GenerateDataKey"]
    resources = [aws_kms_key.agent-lab-key.arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["bedrock-agentcore.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  statement {
    sid       = "CloudWatchMetricsPublish"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["bedrock-agentcore"]
    }
  }
  statement {
    sid       = "EcrPublicTokenAccess"
    effect    = "Allow"
    actions   = ["ecr-public:GetAuthorizationToken", "logs:PutResourcePolicy", "sts:GetServiceBearerToken", "xray:GetSamplingRules", "xray:GetSamplingTargets", "xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
  statement {
    sid       = "AgentCoreWorkloadIdentity"
    effect    = "Allow"
    actions   = ["bedrock-agentcore:GetWorkloadAccessToken", "bedrock-agentcore:GetWorkloadAccessTokenForJWT"]
    resources = ["arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default", "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/harness_agent_lab_orders-*"]
  }
  statement {
    sid       = "BedrockModelInvocation"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.nova-lite-v1:0"]
  }
  statement {
    sid       = "CloudWatchLogsDescribeGroups"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }
  statement {
    sid       = "CloudWatchLogsGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:DescribeLogStreams"]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"]
  }
  statement {
    sid       = "CloudWatchLogsStream"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*"]
  }
}

resource "aws_iam_policy" "bedrockagentcore_harness_agent_lab_orders_st_bedrock-agent-lab" {
  name        = "bedrockagentcore_harness_agent_lab_orders_st_bedrock-agent-lab"
  description = "Access Policy for agent_lab_orders"
  policy      = data.aws_iam_policy_document.bedrockagentcore_harness_agent_lab_orders_st_bedrock-agent-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_agent-lab-chat_st_bedrock-agent-lab_doc" {
  statement {
    sid       = "AllowApplyGuardrail"
    effect    = "Allow"
    actions   = ["bedrock:ApplyGuardrail"]
    resources = [aws_bedrock_guardrail.agent-lab-guardrail.guardrail_arn]
  }
  statement {
    sid       = "AllowInvokeHarness"
    effect    = "Allow"
    actions   = ["bedrock-agentcore:InvokeAgentRuntime", "bedrock-agentcore:InvokeHarness"]
    resources = [aws_bedrockagentcore_harness.agent_lab_orders.arn]
  }
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.agent-lab-chat-logs.arn}:*"]
  }
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
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
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
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

resource "aws_iam_role" "role_agent-lab-gateway" {
  name = "role_agent-lab-gateway"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock-agentcore.amazonaws.com"
      },
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:gateway/*"
        }
      }
    }
  ]
})
  tags = {
    Name           = "role_agent-lab-gateway"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_agent_lab_orders" {
  name = "role_agent_lab_orders"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock-agentcore.amazonaws.com"
      },
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }
  ]
})
  tags = {
    Name           = "role_agent_lab_orders"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "bedrockagentcore_gateway_agent-lab-gateway_st_bedrock-agent-lab_attach" {
  policy_arn = aws_iam_policy.bedrockagentcore_gateway_agent-lab-gateway_st_bedrock-agent-lab.arn
  role       = aws_iam_role.role_agent-lab-gateway.name
}

resource "aws_iam_role_policy_attachment" "bedrockagentcore_harness_agent_lab_orders_st_bedrock-agent-lab_attach" {
  policy_arn = aws_iam_policy.bedrockagentcore_harness_agent_lab_orders_st_bedrock-agent-lab.arn
  role       = aws_iam_role.role_agent_lab_orders.name
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
  timeout                        = 120
  environment {
    variables = {
    NAME                                      = "agent-lab-chat"
    REGION                                    = data.aws_region.current.region
    ACCOUNT                                   = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0            = "agent-lab-chat-url"
    AWS_BEDROCKAGENTCORE_HARNESS_ARN_0        = aws_bedrockagentcore_harness.agent_lab_orders.arn
    AWS_BEDROCK_GUARDRAIL_GUARDRAIL_ID_0      = aws_bedrock_guardrail.agent-lab-guardrail.guardrail_id
    AWS_BEDROCK_GUARDRAIL_GUARDRAIL_VERSION_0 = aws_bedrock_guardrail.agent-lab-guardrail.version
    AWS_XRAY_GROUP_NAME_0                     = "agent-lab-traces"
  }
  }
  tags = {
    Name           = "agent-lab-chat"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  tracing_config {
    mode = "Active"
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
    AWS_XRAY_GROUP_NAME_0     = "agent-lab-traces"
  }
  }
  tags = {
    Name           = "agent-lab-orders-tool"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  tracing_config {
    mode = "Active"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_agent-lab-orders-tool_st_bedrock-agent-lab_attach]
}

resource "aws_lambda_function_url" "agent-lab-chat-url" {
  function_name      = aws_lambda_function.agent-lab-chat.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_agent-lab-chat-url_to_agent-lab-chat" {
  function_name          = aws_lambda_function.agent-lab-chat.function_name
  statement_id           = "perm_aws_lambda_function_url_agent-lab-chat-url_to_agent-lab-chat"
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_agent-lab-chat-url_to_agent-lab-chat_invoke" {
  function_name            = aws_lambda_function.agent-lab-chat.function_name
  statement_id             = "perm_aws_lambda_function_url_agent-lab-chat-url_to_agent-lab-chat_invoke"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
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
      action        = "ANONYMIZE"
      input_action  = "ANONYMIZE"
      output_action = "ANONYMIZE"
      type          = "EMAIL"
    }
  }
  tags = {
    Name           = "agent-lab-guardrail"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrockagentcore_gateway" "agent-lab-gateway" {
  name            = "agent-lab-gateway"
  authorizer_type = "AWS_IAM"
  exception_level = "DEBUG"
  protocol_type   = "MCP"
  role_arn        = aws_iam_role.role_agent-lab-gateway.arn
  tags = {
    Name           = "agent-lab-gateway"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.bedrockagentcore_gateway_agent-lab-gateway_st_bedrock-agent-lab_attach]
}

resource "aws_bedrockagentcore_gateway_target" "orders" {
  name               = "orders"
  gateway_identifier = aws_bedrockagentcore_gateway.agent-lab-gateway.gateway_id
  credential_provider_configuration {
    gateway_iam_role {
    }
  }
  target_configuration {
    mcp {
      lambda {
        lambda_arn = aws_lambda_function.agent-lab-orders-tool.arn
        tool_schema {
          inline_payload {
            name        = "get_order_status"
            description = "Returns the status, item and quantity of one order, looked up by its order id. Call it only with an order id the customer gave."
            input_schema {
              type = "object"
              property {
                name        = "order_id"
                description = "The order id the customer gave."
                required    = true
                type        = "string"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [time_sleep.agent-lab-gateway_role_propagation]
}

resource "aws_bedrockagentcore_harness" "agent_lab_orders" {
  harness_name       = "agent_lab_orders"
  allowed_tools      = ["@agent-lab-gateway"]
  execution_role_arn = aws_iam_role.role_agent_lab_orders.arn
  max_iterations     = 10
  max_tokens         = 4096
  timeout_seconds    = 90
  memory {
    agentcore_memory_configuration {
      arn = aws_bedrockagentcore_memory.agent_lab_memory.arn
      retrieval_config {
        strategy_id     = aws_bedrockagentcore_memory_strategy.session_summaries.memory_strategy_id
        map_block_key   = "/summaries/{actorId}/"
        relevance_score = 0.2
        top_k           = 10
      }
    }
  }
  model {
    bedrock_model_config {
      model_id    = "amazon.nova-lite-v1:0"
      max_tokens  = 1024
      temperature = 0.2
    }
  }
  system_prompt {
    text = "You are the order assistant of Bean Lab Coffee, a fictional coffee roaster used in a lab. Answer questions about orders. To learn the status of an order, call the get_order_status tool with the order id, even when the user context mentions that order, since its status may have changed. The user context, when present, summarizes this customer's earlier conversations: use it to answer questions about them and to find an order id the customer already gave. Never make up order details; if the tool says an order was not found, say so. Use only an order id that the question or the user context gives, never one you guess; when neither gives one, ask the customer for it. Keep answers short."
  }
  tags = {
    Name           = "agent_lab_orders"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  tool {
    name = "agent-lab-gateway"
    type = "agentcore_gateway"
    config {
      agentcore_gateway {
        gateway_arn = aws_bedrockagentcore_gateway.agent-lab-gateway.gateway_arn
        outbound_auth {
          aws_iam = true
        }
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.bedrockagentcore_harness_agent_lab_orders_st_bedrock-agent-lab_attach]
}

resource "aws_bedrockagentcore_memory" "agent_lab_memory" {
  name                  = "agent_lab_memory"
  encryption_key_arn    = aws_kms_key.agent-lab-key.arn
  event_expiry_duration = 30
  tags = {
    Name           = "agent_lab_memory"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrockagentcore_memory_strategy" "session_summaries" {
  memory_id           = aws_bedrockagentcore_memory.agent_lab_memory.id
  name                = "session_summaries"
  namespace_templates = ["/summaries/{actorId}/{sessionId}"]
  type                = "SUMMARIZATION"
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

resource "aws_xray_group" "agent-lab-traces" {
  group_name        = "agent-lab-traces"
  filter_expression = "service(\"agent-lab-chat\") OR service(\"agent-lab-orders-tool\")"
  tags = {
    Name           = "agent-lab-traces"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MISC ###

resource "time_sleep" "agent-lab-gateway_role_propagation" {
  create_duration = "30s"
  triggers = {
    role = aws_iam_role.role_agent-lab-gateway.unique_id
  }
}


