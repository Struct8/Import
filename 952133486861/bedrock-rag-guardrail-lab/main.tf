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
    key     = "952133486861/bedrock-rag-guardrail-lab/main.tfstate"
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

data "aws_iam_policy_document" "bedrockagent_knowledge_base_bedrock-kb-lab_st_bedrock-rag-guardrail-lab_doc" {
  statement {
    sid       = "ListTheDocuments"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bedrock-documents.arn]
  }
  statement {
    sid       = "ReadTheDocuments"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bedrock-documents.arn}/*"]
  }
  statement {
    sid       = "UseTheVectorIndex"
    effect    = "Allow"
    actions   = ["s3vectors:DeleteVectors", "s3vectors:GetIndex", "s3vectors:GetVectors", "s3vectors:PutVectors", "s3vectors:QueryVectors"]
    resources = [aws_s3vectors_index.bedrock-kb-index.index_arn]
  }
  statement {
    sid       = "InvokeTheEmbeddingModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.titan-embed-text-v2:0"]
  }
}

resource "aws_iam_policy" "bedrockagent_knowledge_base_bedrock-kb-lab_st_bedrock-rag-guardrail-lab" {
  name        = "bedrockagent_knowledge_base_bedrock-kb-lab_st_bedrock-rag-guardrail-lab"
  description = "Access Policy for bedrock-kb-lab"
  policy      = data.aws_iam_policy_document.bedrockagent_knowledge_base_bedrock-kb-lab_st_bedrock-rag-guardrail-lab_doc.json
}

data "aws_iam_policy_document" "lambda_function_bedrock-rag-handler_st_bedrock-rag-guardrail-lab_doc" {
  statement {
    sid       = "AllowApplyGuardrail"
    effect    = "Allow"
    actions   = ["bedrock:ApplyGuardrail"]
    resources = [aws_bedrock_guardrail.lab-guardrail.guardrail_arn]
  }
  statement {
    sid       = "AllowInvokeInferenceProfile"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = [aws_bedrock_inference_profile.bedrock-rag-answer-model.arn]
  }
  statement {
    sid       = "AllowKnowledgeBaseRetrieve"
    effect    = "Allow"
    actions   = ["bedrock:Retrieve"]
    resources = [aws_bedrockagent_knowledge_base.bedrock-kb-lab.arn]
  }
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.bedrock-rag-handler-logs.arn}:*"]
  }
  statement {
    sid       = "AllowRetrieveAndGenerate"
    effect    = "Allow"
    actions   = ["bedrock:RetrieveAndGenerate"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowInferenceProfileModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
    resources = ["arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.nova-lite-v1:0"]
  }
  statement {
    sid       = "AllowDataSourceSync"
    effect    = "Allow"
    actions   = ["bedrock:GetIngestionJob", "bedrock:ListIngestionJobs", "bedrock:StartIngestionJob"]
    resources = ["arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:knowledge-base/${aws_bedrockagent_data_source.bedrock-rag-documents.knowledge_base_id}"]
  }
}

resource "aws_iam_policy" "lambda_function_bedrock-rag-handler_st_bedrock-rag-guardrail-lab" {
  name        = "lambda_function_bedrock-rag-handler_st_bedrock-rag-guardrail-lab"
  description = "Access Policy for bedrock-rag-handler"
  policy      = data.aws_iam_policy_document.lambda_function_bedrock-rag-handler_st_bedrock-rag-guardrail-lab_doc.json
}

resource "aws_iam_role" "bedrock-rag-handler_role" {
  name = "bedrock-rag-handler_role"
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
    Name           = "bedrock-rag-handler_role"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_kb_bedrock-kb-lab" {
  name = "role_kb_bedrock-kb-lab"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock.amazonaws.com"
      },
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
        }
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "role_kb_bedrock-kb-lab"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "bedrockagent_knowledge_base_bedrock-kb-lab_st_bedrock-rag-guardrail-lab_attach" {
  policy_arn = aws_iam_policy.bedrockagent_knowledge_base_bedrock-kb-lab_st_bedrock-rag-guardrail-lab.arn
  role       = aws_iam_role.role_kb_bedrock-kb-lab.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_bedrock-rag-handler_st_bedrock-rag-guardrail-lab_attach" {
  policy_arn = aws_iam_policy.lambda_function_bedrock-rag-handler_st_bedrock-rag-guardrail-lab.arn
  role       = aws_iam_role.bedrock-rag-handler_role.name
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "bedrock-documents" {
  bucket              = "bedrock-documents-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "bedrock-documents"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "bedrock-documents_controls" {
  bucket = aws_s3_bucket.bedrock-documents.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "bedrock-documents_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.bedrock-documents.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock-documents_configuration" {
  bucket = aws_s3_bucket.bedrock-documents.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "bedrock-documents_versioning" {
  bucket = aws_s3_bucket.bedrock-documents.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "bedrock-rag-documents-files" {
  for_each     = fileset("${path.module}/.external_modules/struct8-templates/templates/bedrock-rag-lab/v1/documents", "**")
  source       = "${path.module}/.external_modules/struct8-templates/templates/bedrock-rag-lab/v1/documents/${each.value}"
  bucket       = aws_s3_bucket.bedrock-documents.bucket
  content_type = lookup({ "md" = "text/markdown; charset=utf-8" }, lower(regex("[^.]*$", each.value)), "application/octet-stream")
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/bedrock-rag-lab/v1/documents/${each.value}")
  key          = each.value
  tags = {
    Name           = "bedrock-rag-documents-files"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3vectors_index" "bedrock-kb-index" {
  index_name         = "bedrock-kb-index"
  vector_bucket_name = aws_s3vectors_vector_bucket.bedrock-vectors.vector_bucket_name
  data_type          = "float32"
  dimension          = 1024
  distance_metric    = "cosine"
  metadata_configuration {
    non_filterable_metadata_keys = ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]
  }
  tags = {
    Name           = "bedrock-kb-index"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3vectors_vector_bucket" "bedrock-vectors" {
  vector_bucket_name = "bedrock-vectors"
  force_destroy      = false
  tags = {
    Name           = "bedrock-vectors"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-templates_bedrock-rag-handler" {
  output_path = "${path.module}/struct8-templates_bedrock-rag-handler.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/bedrock-rag-lab/v1/lambda/rag-handler"
  type        = "zip"
}

resource "aws_lambda_function" "bedrock-rag-handler" {
  function_name                  = "bedrock-rag-handler"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-templates_bedrock-rag-handler.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.bedrock-rag-handler_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-templates_bedrock-rag-handler.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
    NAME                                             = "bedrock-rag-handler"
    REGION                                           = data.aws_region.current.region
    ACCOUNT                                          = data.aws_caller_identity.current.account_id
    AWS_LAMBDA_FUNCTION_URL_NAME_0                   = "bedrock-rag-url"
    AWS_BEDROCK_INFERENCE_PROFILE_ARN_0              = aws_bedrock_inference_profile.bedrock-rag-answer-model.arn
    AWS_BEDROCKAGENT_KNOWLEDGE_BASE_ID_0             = aws_bedrockagent_knowledge_base.bedrock-kb-lab.id
    AWS_BEDROCKAGENT_DATA_SOURCE_ID_0                = aws_bedrockagent_data_source.bedrock-rag-documents.data_source_id
    AWS_BEDROCKAGENT_DATA_SOURCE_KNOWLEDGE_BASE_ID_0 = aws_bedrockagent_data_source.bedrock-rag-documents.knowledge_base_id
    AWS_BEDROCK_GUARDRAIL_GUARDRAIL_ID_0             = aws_bedrock_guardrail.lab-guardrail.guardrail_id
    AWS_BEDROCK_GUARDRAIL_GUARDRAIL_VERSION_0        = aws_bedrock_guardrail.lab-guardrail.version
  }
  }
  tags = {
    Name           = "bedrock-rag-handler"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_bedrock-rag-handler_st_bedrock-rag-guardrail-lab_attach]
}

resource "aws_lambda_function_url" "bedrock-rag-url" {
  function_name      = aws_lambda_function.bedrock-rag-handler.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_bedrock-rag-url_to_bedrock-rag-handler" {
  function_name          = aws_lambda_function.bedrock-rag-handler.function_name
  statement_id           = "perm_aws_lambda_function_url_bedrock-rag-url_to_bedrock-rag-handler"
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_bedrock-rag-url_to_bedrock-rag-handler_invoke" {
  function_name            = aws_lambda_function.bedrock-rag-handler.function_name
  statement_id             = "perm_aws_lambda_function_url_bedrock-rag-url_to_bedrock-rag-handler_invoke"
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
}




### CATEGORY: AI ###

resource "aws_bedrock_guardrail" "lab-guardrail" {
  name                      = "lab-guardrail"
  blocked_input_messaging   = "Sorry, the model cannot answer this question."
  blocked_outputs_messaging = "Sorry, the model cannot answer this question."
  content_policy_config {
    filters_config {
      input_strength  = "HIGH"
      output_strength = "NONE"
      type            = "PROMPT_ATTACK"
    }
  }
  contextual_grounding_policy_config {
    filters_config {
      threshold = 0.75
      type      = "GROUNDING"
    }
    filters_config {
      threshold = 0.5
      type      = "RELEVANCE"
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
    Name           = "lab-guardrail"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrock_inference_profile" "bedrock-rag-answer-model" {
  name = "bedrock-rag-answer-model"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.nova-lite-v1:0"
  }
  tags = {
    Name           = "bedrock-rag-answer-model"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrockagent_data_source" "bedrock-rag-documents" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.bedrock-kb-lab1.id
  name              = "bedrock-rag-documents"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.bedrock-documents.arn
    }
  }
}

resource "aws_bedrockagent_knowledge_base" "bedrock-kb-lab" {
  name     = "bedrock-kb-lab"
  role_arn = aws_iam_role.role_kb_bedrock-kb-lab.arn
  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }
  storage_configuration {
    type = "S3_VECTORS"
    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.bedrock-kb-index.index_arn
    }
  }
  tags = {
    Name           = "bedrock-kb-lab"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.bedrockagent_knowledge_base_bedrock-kb-lab_st_bedrock-rag-guardrail-lab_attach]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "bedrock-rag-handler-logs" {
  name              = "/aws/lambda/bedrock-rag-handler"
  log_group_class   = "STANDARD"
  retention_in_days = 7
  skip_destroy      = false
  tags = {
    Name           = "bedrock-rag-handler-logs"
    State          = "bedrock-rag-guardrail-lab"
    Struct8Creator = "Contato Struct"
  }
}


