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
    name = "agent-lab-chat-permissions"
    policy = <<EOF
{"Version":"2012-10-17","Statement":[{"Sid":"InvokeTheHarness","Effect":"Allow","Action":["bedrock-agentcore:InvokeHarness","bedrock-agentcore:InvokeAgentRuntime"],"Resource":"${aws_bedrockagentcore_harness.agent-lab-harness.arn}"},{"Sid":"ApplyTheGuardrail","Effect":"Allow","Action":"bedrock:ApplyGuardrail","Resource":"${aws_bedrock_guardrail.agent-lab-guardrail.guardrail_arn}"}]}
  EOF
  }
  tags = {
    Name           = "agent-lab-chat_role"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "agent-lab-gateway-role" {
  # ajuste manual · assume_role_policy — No wire writes this trust policy: aws_bedrockagentcore_gateway is an uncurated type, so nothing fills the trust of the role it names in role_arn. The gateway assumes its role as bedrock-agentcore.amazonaws.com; the conditions limit that to gateways of this account and region.
  name                  = "agent-lab-gateway-role"
  assume_role_policy    = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "bedrock-agentcore.amazonaws.com" }, Action = "sts:AssumeRole", Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }, ArnLike = { "aws:SourceArn" = "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:gateway/*" } } }] })
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  inline_policy {
    name = "agent-lab-gateway-permissions"
    policy = <<EOF
{"Version":"2012-10-17","Statement":[{"Sid":"InvokeTheOrdersTool","Effect":"Allow","Action":"lambda:InvokeFunction","Resource":"${aws_lambda_function.agent-lab-orders-tool.arn}"}]}
  EOF
  }
  tags = {
    Name           = "agent-lab-gateway-role"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "agent-lab-harness-role" {
  # ajuste manual · assume_role_policy — No wire writes this trust policy: aws_bedrockagentcore_harness is an uncurated type, so nothing fills the trust of the role it names in execution_role_arn. The harness assumes its execution role as bedrock-agentcore.amazonaws.com; the conditions limit that to AgentCore resources of this account and region.
  name                  = "agent-lab-harness-role"
  assume_role_policy    = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "bedrock-agentcore.amazonaws.com" }, Action = "sts:AssumeRole", Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }, ArnLike = { "aws:SourceArn" = "arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*" } } }] })
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  inline_policy {
    name = "agent-lab-harness-permissions"
    policy = <<EOF
{"Version":"2012-10-17","Statement":[{"Sid":"InvokeNovaLite","Effect":"Allow","Action":["bedrock:InvokeModel","bedrock:InvokeModelWithResponseStream"],"Resource":"arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.nova-lite-v1:0"},{"Sid":"PullTheManagedImage","Effect":"Allow","Action":["ecr-public:GetAuthorizationToken","sts:GetServiceBearerToken"],"Resource":"*"},{"Sid":"CallTheOrdersGateway","Effect":"Allow","Action":"bedrock-agentcore:InvokeGateway","Resource":"${aws_bedrockagentcore_gateway.agent-lab-gateway.gateway_arn}"},{"Sid":"UseTheMemory","Effect":"Allow","Action":["bedrock-agentcore:CreateEvent","bedrock-agentcore:DeleteEvent","bedrock-agentcore:GetEvent","bedrock-agentcore:ListEvents","bedrock-agentcore:RetrieveMemoryRecords"],"Resource":"${aws_bedrockagentcore_memory.agent-lab-memory.arn}"},{"Sid":"UseTheMemoryKey","Effect":"Allow","Action":["kms:Decrypt","kms:DescribeKey","kms:GenerateDataKey"],"Resource":"${aws_kms_key.agent-lab-key.arn}","Condition":{"StringEquals":{"kms:ViaService":"bedrock-agentcore.${data.aws_region.current.region}.amazonaws.com"}}},{"Sid":"GetWorkloadToken","Effect":"Allow","Action":["bedrock-agentcore:GetWorkloadAccessToken","bedrock-agentcore:GetWorkloadAccessTokenForJWT"],"Resource":["arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default","arn:aws:bedrock-agentcore:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:workload-identity-directory/default/workload-identity/*"]},{"Sid":"WriteRuntimeLogs","Effect":"Allow","Action":["logs:CreateLogGroup","logs:DescribeLogStreams","logs:CreateLogStream","logs:PutLogEvents"],"Resource":["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*","arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*"]},{"Sid":"DescribeLogGroups","Effect":"Allow","Action":"logs:DescribeLogGroups","Resource":"arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"},{"Sid":"LogDeliveryPolicy","Effect":"Allow","Action":"logs:PutResourcePolicy","Resource":"*"},{"Sid":"Traces","Effect":"Allow","Action":["xray:PutTraceSegments","xray:PutTelemetryRecords","xray:GetSamplingRules","xray:GetSamplingTargets"],"Resource":"*"},{"Sid":"Metrics","Effect":"Allow","Action":"cloudwatch:PutMetricData","Resource":"*","Condition":{"StringEquals":{"cloudwatch:namespace":"bedrock-agentcore"}}}]}
  EOF
  }
  tags = {
    Name           = "agent-lab-harness-role"
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
    HARNESS_ARN                    = aws_bedrockagentcore_harness.agent-lab-harness.arn
    GUARDRAIL_ID                   = aws_bedrock_guardrail.agent-lab-guardrail.guardrail_id
    GUARDRAIL_VERSION              = aws_bedrock_guardrail.agent-lab-guardrail.version
    NAME                           = "agent-lab-chat"
    REGION                         = data.aws_region.current.region
    ACCOUNT                        = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0 = "agent-lab-chat-url"
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
  role_arn        = aws_iam_role.agent-lab-gateway-role.arn
  tags = {
    Name           = "agent-lab-gateway"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrockagentcore_gateway_target" "orders" {
  # ajuste manual · credential_provider_configuration — The compile drops the empty gateway_iam_role block that is stored on this node, and the provider requires credential_provider_configuration on a Lambda target: the gateway invokes the function with its own IAM role.
  # ajuste manual · depends_on — CreateGatewayTarget refuses the target while the trust policy of the gateway role is still propagating (it failed 3 s after the role was created), and the provider retries only the permissions error, not this one. Waiting for the memory, which takes about 3 minutes to create, gives the role that time without making the apply longer: the harness waits for the memory anyway.
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
            description = "Returns the status, item and quantity of one order, looked up by its order id."
            input_schema {
              type = "object"
              property {
                name        = "order_id"
                description = "The order id, for example 1001."
                required    = true
                type        = "string"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [aws_bedrockagentcore_memory.agent-lab-memory]
}

resource "aws_bedrockagentcore_harness" "agent-lab-harness" {
  # ajuste manual · system_prompt[*].text — The compile rewrites this text on an uncurated type: it removes the space after each comma and wraps the part between the first and last comma in ${...}, which Terraform would read as an expression. Written as a quoted expression so it reaches the file unchanged.
  harness_name       = "agent_lab_orders"
  allowed_tools      = ["@orders_gateway"]
  execution_role_arn = aws_iam_role.agent-lab-harness-role.arn
  max_iterations     = 10
  max_tokens         = 4096
  timeout_seconds    = 90
  memory {
    agentcore_memory_configuration {
      arn = aws_bedrockagentcore_memory.agent-lab-memory.arn
      retrieval_config {
        strategy_id     = aws_bedrockagentcore_memory_strategy.agent-lab-session-summaries.memory_strategy_id
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
    text = "You are the order assistant of Bean Lab Coffee, a fictional coffee roaster used in a lab. Answer questions about orders. To learn the status of an order, call the get_order_status tool with the order id. The user context, when present, summarizes this customer's earlier conversations: use it to answer questions about them and to find an order id the customer already gave. Answer only with what the tool or the user context says; if the tool says an order was not found, say so. Ask for an order id only when neither the question nor the user context gives one. Keep answers short."
  }
  tags = {
    Name           = "agent-lab-harness"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
  tool {
    name = "orders_gateway"
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
}

resource "aws_bedrockagentcore_memory" "agent-lab-memory" {
  name                  = "agent_lab_memory"
  encryption_key_arn    = aws_kms_key.agent-lab-key.arn
  event_expiry_duration = 30
  tags = {
    Name           = "agent-lab-memory"
    State          = "bedrock-agent-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrockagentcore_memory_strategy" "agent-lab-session-summaries" {
  memory_id  = aws_bedrockagentcore_memory.agent-lab-memory.id
  name       = "session_summaries"
  namespaces = ["/summaries/{actorId}/{sessionId}"]
  type       = "SUMMARIZATION"
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


