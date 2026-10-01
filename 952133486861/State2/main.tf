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
    key     = "952133486861/State2/main.tfstate"
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

data "aws_iam_policy_document" "lambda_function_Function_st_State2_doc" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.my-bucket1.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.my-bucket1.arn}/*"]
  }
}

resource "aws_iam_policy" "lambda_function_Function_st_State2" {
  name        = "lambda_function_Function_st_State2"
  description = "Access Policy for Function"
  policy      = data.aws_iam_policy_document.lambda_function_Function_st_State2_doc.json
}

resource "aws_iam_role" "Function2_role" {
  name = "Function2_role"
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
    Name           = "Function2_role"
    State          = "State2"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "Function_role" {
  name = "Function_role"
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
    Name           = "Function_role"
    State          = "State2"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_Function_st_State2_attach" {
  policy_arn = aws_iam_policy.lambda_function_Function_st_State2.arn
  role       = aws_iam_role.Function_role.name
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "my-bucket1" {
  bucket              = "my-bucket1-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = false
  object_lock_enabled = false
  tags = {
    Name           = "my-bucket1"
    State          = "State2"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "my-bucket1_controls" {
  bucket = aws_s3_bucket.my-bucket1.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "my-bucket1_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.my-bucket1.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my-bucket1_configuration" {
  bucket = aws_s3_bucket.my-bucket1.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "my-bucket1_versioning" {
  bucket = aws_s3_bucket.my-bucket1.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}




### CATEGORY: COMPUTE ###

data "archive_file" "archive_CloudManMainV2_Function" {
  output_path = "${path.module}/CloudManMainV2_Function.zip"
  source_dir  = "${path.module}/.external_modules/CloudManMainV2/LambdaFiles/LambdaHub2"
  type        = "zip"
}

resource "aws_lambda_function" "Function" {
  function_name                  = "Function"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_CloudManMainV2_Function.output_path
  handler                        = "LambdaHub2.lambda_handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.Function_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_CloudManMainV2_Function.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                 = "Function"
    REGION               = data.aws_region.current.region
    ACCOUNT              = data.aws_caller_identity.current.account_id
    AWS_S3_BUCKET_NAME_0 = "my-bucket1-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  }
  }
  tags = {
    Name           = "Function"
    State          = "State2"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_Function_st_State2_attach]
}

data "archive_file" "archive_CloudManMainV2_Function2" {
  output_path = "${path.module}/CloudManMainV2_Function2.zip"
  source_dir  = "${path.module}/.external_modules/CloudManMainV2/LambdaFiles/Redirector"
  type        = "zip"
}

resource "aws_lambda_function" "Function2" {
  function_name                  = "Function2"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_CloudManMainV2_Function2.output_path
  handler                        = "Redirector.lambda_handler"
  memory_size                    = 3008
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.Function2_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_CloudManMainV2_Function2.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME    = "Function2"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "Function2"
    State          = "State2"
    Struct8Creator = "Contato Struct"
  }
}


