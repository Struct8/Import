terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State1/main.tfstate"
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

data "aws_lambda_function" "Function" {
  function_name = "Function"
}

data "aws_lambda_function" "Function2" {
  function_name = "Function2"
}

data "aws_s3_bucket" "my-bucket1" {
  bucket = "my-bucket1-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "User_role_access_0_doc" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:CreateAlias", "lambda:CreateFunctionUrlConfig", "lambda:DeleteAlias", "lambda:DeleteFunctionCodeSigningConfig", "lambda:DeleteFunctionConcurrency", "lambda:DeleteFunctionEventInvokeConfig", "lambda:DeleteFunctionUrlConfig", "lambda:GetAlias", "lambda:GetFunction", "lambda:GetFunctionCodeSigningConfig", "lambda:GetFunctionConcurrency", "lambda:GetFunctionConfiguration", "lambda:GetFunctionEventInvokeConfig", "lambda:GetFunctionRecursionConfig", "lambda:GetFunctionScalingConfig", "lambda:GetFunctionUrlConfig", "lambda:GetPolicy", "lambda:GetRuntimeManagementConfig", "lambda:InvokeAsync", "lambda:InvokeFunction", "lambda:InvokeFunctionUrl", "lambda:ListAliases", "lambda:ListDurableExecutionsByFunction", "lambda:ListFunctionEventInvokeConfigs", "lambda:ListFunctionUrlConfigs", "lambda:ListProvisionedConcurrencyConfigs", "lambda:ListTags", "lambda:ListVersionsByFunction", "lambda:PublishVersion", "lambda:PutFunctionConcurrency", "lambda:PutFunctionEventInvokeConfig", "lambda:PutFunctionRecursionConfig", "lambda:PutFunctionScalingConfig", "lambda:PutRuntimeManagementConfig", "lambda:UpdateAlias", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration", "lambda:UpdateFunctionEventInvokeConfig", "lambda:UpdateFunctionUrlConfig"]
    resources = [data.aws_lambda_function.Function.arn, data.aws_lambda_function.Function2.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:DeleteProvisionedConcurrencyConfig", "lambda:GetProvisionedConcurrencyConfig", "lambda:PutProvisionedConcurrencyConfig"]
    resources = ["${data.aws_lambda_function.Function.arn}:*", "${data.aws_lambda_function.Function2.arn}:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:CheckpointDurableExecution", "lambda:GetDurableExecution", "lambda:GetDurableExecutionHistory", "lambda:GetDurableExecutionState", "lambda:SendDurableExecutionCallbackFailure", "lambda:SendDurableExecutionCallbackHeartbeat", "lambda:SendDurableExecutionCallbackSuccess", "lambda:StopDurableExecution"]
    resources = ["${data.aws_lambda_function.Function.arn}:*/durable-execution/*/*", "${data.aws_lambda_function.Function2.arn}:*/durable-execution/*/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:AllowVendedLogDeliveryForResource", "s3:CreateBucketMetadataTableConfiguration", "s3:DeleteBucketMetadataTableConfiguration", "s3:DeleteBucketWebsite", "s3:GetAccelerateConfiguration", "s3:GetAnalyticsConfiguration", "s3:GetBucketAbac", "s3:GetBucketAcl", "s3:GetBucketCORS", "s3:GetBucketLocation", "s3:GetBucketLogging", "s3:GetBucketMetadataTableConfiguration", "s3:GetBucketNotification", "s3:GetBucketObjectLockConfiguration", "s3:GetBucketOwnershipControls", "s3:GetBucketPolicy", "s3:GetBucketPolicyStatus", "s3:GetBucketPublicAccessBlock", "s3:GetBucketRequestPayment", "s3:GetBucketTagging", "s3:GetBucketVersioning", "s3:GetBucketWebsite", "s3:GetEncryptionConfiguration", "s3:GetIntelligentTieringConfiguration", "s3:GetInventoryConfiguration", "s3:GetLifecycleConfiguration", "s3:GetMetricsConfiguration", "s3:GetReplicationConfiguration", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:ListBucketVersions", "s3:ListTagsForResource", "s3:PauseReplication", "s3:PutAccelerateConfiguration", "s3:PutAnalyticsConfiguration", "s3:PutBucketAbac", "s3:PutBucketCORS", "s3:PutBucketLogging", "s3:PutBucketNotification", "s3:PutBucketObjectLockConfiguration", "s3:PutBucketRequestPayment", "s3:PutBucketVersioning", "s3:PutBucketWebsite", "s3:PutEncryptionConfiguration", "s3:PutIntelligentTieringConfiguration", "s3:PutInventoryConfiguration", "s3:PutLifecycleConfiguration", "s3:PutMetricsConfiguration", "s3:PutReplicationConfiguration", "s3:UpdateBucketMetadataAnnotationTableConfiguration", "s3:UpdateBucketMetadataInventoryTableConfiguration", "s3:UpdateBucketMetadataJournalTableConfiguration"]
    resources = [data.aws_s3_bucket.my-bucket1.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:AbortMultipartUpload", "s3:DeleteObject", "s3:DeleteObjectAnnotation", "s3:DeleteObjectVersion", "s3:DeleteObjectVersionAnnotation", "s3:GetObject", "s3:GetObjectAcl", "s3:GetObjectAnnotation", "s3:GetObjectAttributes", "s3:GetObjectLegalHold", "s3:GetObjectRetention", "s3:GetObjectTagging", "s3:GetObjectTorrent", "s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionAnnotation", "s3:GetObjectVersionAnnotationForReplication", "s3:GetObjectVersionAttributes", "s3:GetObjectVersionForReplication", "s3:GetObjectVersionTagging", "s3:GetObjectVersionTorrent", "s3:InitiateReplication", "s3:ListMultipartUploadParts", "s3:ListObjectAnnotations", "s3:ListObjectVersionAnnotations", "s3:PutObject", "s3:PutObjectAnnotation", "s3:PutObjectLegalHold", "s3:PutObjectRetention", "s3:PutObjectVersionAnnotation", "s3:ReplicateDelete", "s3:ReplicateObject", "s3:ReplicateObjectAnnotation", "s3:RestoreObject", "s3:UpdateObjectEncryption"]
    resources = ["${data.aws_s3_bucket.my-bucket1.arn}/*"]
  }
}

resource "aws_iam_policy" "User_role_access_0" {
  name   = "User_role-access-0"
  policy = data.aws_iam_policy_document.User_role_access_0_doc.json
}

data "aws_iam_policy_document" "User_role_access_1_doc" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:ConnectMicrovm", "lambda:CreateCodeSigningConfig", "lambda:CreateEventSourceMapping", "lambda:CreateMicrovmImage", "lambda:GetAccountSettings", "lambda:ListCapacityProviders", "lambda:ListCodeSigningConfigs", "lambda:ListEventSourceMappings", "lambda:ListFunctions", "lambda:ListLayerVersions", "lambda:ListLayers", "lambda:ListManagedMicrovmImages", "lambda:ListMicrovmImages", "lambda:ListMicrovms", "lambda:ListNetworkConnectors", "lambda:PassNetworkConnector", "s3:CreateJob", "s3:CreateStorageLensGroup", "s3:GetAccessPoint", "s3:GetAccountPublicAccessBlock", "s3:ListAccessGrantsInstances", "s3:ListAccessPoints", "s3:ListAccessPointsForObjectLambda", "s3:ListAllMyBuckets", "s3:ListJobs", "s3:ListMultiRegionAccessPoints", "s3:ListStorageLensConfigurations", "s3:ListStorageLensGroups", "s3:PutStorageLensConfiguration"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "User_role_access_1" {
  name   = "User_role-access-1"
  policy = data.aws_iam_policy_document.User_role_access_1_doc.json
}

data "aws_iam_policy_document" "User_role_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [aws_iam_user.User.arn]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "User_role" {
  name                  = "User_role"
  assume_role_policy    = data.aws_iam_policy_document.User_role_trust.json
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
}

resource "aws_iam_role_policy_attachment" "User_role_access_0_attach" {
  policy_arn = aws_iam_policy.User_role_access_0.arn
  role       = aws_iam_role.User_role.name
}

resource "aws_iam_role_policy_attachment" "User_role_access_1_attach" {
  policy_arn = aws_iam_policy.User_role_access_1.arn
  role       = aws_iam_role.User_role.name
}

resource "aws_iam_user" "User" {
  name          = "User"
  force_destroy = true
  tags = {
    Name           = "User"
    State          = "State1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_user_login_profile" "login_User" {
  password_length         = 20
  password_reset_required = true
  user                    = aws_iam_user.User.name
}


