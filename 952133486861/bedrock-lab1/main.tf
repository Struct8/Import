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
    key     = "952133486861/bedrock-lab1/main.tfstate"
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

resource "aws_iam_role" "bedrock-kb-role" {
  # ajuste manual · assume_role_policy — No wire writes this trust policy: aws_bedrockagent_knowledge_base declares no roles:, so a role wired to it reaches the plan without one. Bedrock assumes the knowledge base role as bedrock.amazonaws.com; the conditions limit that to knowledge bases of this account and region.
  name                  = "bedrock-kb-role"
  assume_role_policy    = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "bedrock.amazonaws.com" }, Action = "sts:AssumeRole", Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }, ArnLike = { "aws:SourceArn" = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*" } } }] })
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "bedrock-kb-role"
    State          = "bedrock-lab1"
    Struct8Creator = "Contato Struct"
  }
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
    State          = "bedrock-lab1"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "bedrock-documents" {
  bucket              = "bedrock-documents-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = false
  object_lock_enabled = false
  tags = {
    Name           = "bedrock-documents"
    State          = "bedrock-lab1"
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

resource "aws_s3vectors_index" "bedrock-kb-index" {
  index_name         = "bedrock-kb-index"
  vector_bucket_name = aws_s3vectors_vector_bucket.bedrock-vectors.vector_bucket_name
  data_type          = "float32"
  dimension          = 1024
  distance_metric    = "cosine"
  tags = {
    Name           = "bedrock-kb-index"
    State          = "bedrock-lab1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3vectors_vector_bucket" "bedrock-vectors" {
  vector_bucket_name = "my-vector-bucket"
  force_destroy      = false
  tags = {
    Name           = "bedrock-vectors"
    State          = "bedrock-lab1"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_struct8-templates_bedrock-rag-handler" {
  output_path = "${path.module}/struct8-templates_bedrock-rag-handler.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/bedrock-lab1/v1/lambda/rag-handler"
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
  timeout                        = 30
  environment {
    variables = {
    NAME    = "bedrock-rag-handler"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "bedrock-rag-handler"
    State          = "bedrock-lab1"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: AI ###

resource "aws_bedrock_guardrail" "lab1-guardrail" {
  name                      = "lab1-guardrail"
  blocked_input_messaging   = "Sorry, the model cannot answer this question."
  blocked_outputs_messaging = "Sorry, the model cannot answer this question."
  tags = {
    Name           = "lab1-guardrail"
    State          = "bedrock-lab1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrockagent_knowledge_base" "bedrock-kb-lab1" {
  name     = "bedrock-kb-lab1"
  role_arn = aws_iam_role.bedrock-kb-role.arn
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
    Name           = "bedrock-kb-lab1"
    State          = "bedrock-lab1"
    Struct8Creator = "Contato Struct"
  }
}


