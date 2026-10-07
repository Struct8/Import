terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/gitops-engine-codebuild-runner/main.tfstate"
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

data "aws_codestarconnections_connection" "struct8-engine-github" {
  name = "struct8-engine-github"
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "codebuild_project_struct8-engine_st_gitops-engine-codebuild-runner_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.struct8-engine-logs.arn}:*"]
  }
  statement {
    sid       = "AllowUseOfConnection"
    effect    = "Allow"
    actions   = ["codeconnections:GetConnection", "codeconnections:GetConnectionToken", "codestar-connections:GetConnection", "codestar-connections:GetConnectionToken"]
    resources = [data.aws_codestarconnections_connection.struct8-engine-github.arn]
  }
  statement {
    sid       = "PublishTestReportsOfThisProject"
    effect    = "Allow"
    actions   = ["codebuild:BatchPutCodeCoverages", "codebuild:BatchPutTestCases", "codebuild:CreateReport", "codebuild:CreateReportGroup", "codebuild:UpdateReport"]
    resources = ["arn:aws:codebuild:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:report-group/struct8-engine-*"]
  }
}

resource "aws_iam_policy" "codebuild_project_struct8-engine_st_gitops-engine-codebuild-runner" {
  name        = "codebuild_project_struct8-engine_st_gitops-engine-codebuild-runner"
  description = "Access Policy for struct8-engine"
  policy      = data.aws_iam_policy_document.codebuild_project_struct8-engine_st_gitops-engine-codebuild-runner_doc.json
}

resource "aws_iam_role" "struct8-engine_role" {
  name = "struct8-engine_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "struct8-engine_role"
    State          = "gitops-engine-codebuild-runner"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_project_struct8-engine_st_gitops-engine-codebuild-runner_attach" {
  policy_arn = aws_iam_policy.codebuild_project_struct8-engine_st_gitops-engine-codebuild-runner.arn
  role       = aws_iam_role.struct8-engine_role.name
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "struct8-engine-logs" {
  name              = "/aws/codebuild/struct8-engine"
  log_group_class   = "STANDARD"
  retention_in_days = 14
  skip_destroy      = false
  tags = {
    Name           = "struct8-engine-logs"
    State          = "gitops-engine-codebuild-runner"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DEVTOOLS ###

resource "aws_codebuild_project" "struct8-engine" {
  source {
    git_clone_depth     = 1
    location            = "https://github.com/Struct8/Import.git"
    report_build_status = false
    type                = "GITHUB"
    auth {
      resource = data.aws_codestarconnections_connection.struct8-engine-github.arn
      type     = "CODECONNECTIONS"
    }
  }
  name             = "struct8-engine"
  auto_retry_limit = 0
  build_timeout    = 480
  description      = "Runs the GitOps engine's GitHub Actions jobs whose runs-on label names this project."
  service_role     = aws_iam_role.struct8-engine_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:8.0"
    privileged_mode = true
    type            = "LINUX_CONTAINER"
    environment_variable {
      name  = "NAME"
      type  = "PLAINTEXT"
      value = "struct8-engine"
    }
    environment_variable {
      name  = "REGION"
      type  = "PLAINTEXT"
      value = data.aws_region.current.region
    }
    environment_variable {
      name  = "ACCOUNT"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_ARN_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.struct8-engine-github.arn
    }
    environment_variable {
      name  = "AWS_CODECONNECTIONS_CONNECTION_NAME_0"
      type  = "PLAINTEXT"
      value = data.aws_codestarconnections_connection.struct8-engine-github.name
    }
  }
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.struct8-engine-logs.name
      status     = "ENABLED"
    }
  }
  tags = {
    Name           = "struct8-engine"
    State          = "gitops-engine-codebuild-runner"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.codebuild_project_struct8-engine_st_gitops-engine-codebuild-runner_attach]
}

resource "aws_codebuild_webhook" "struct8-engine_webhook" {
  project_name = aws_codebuild_project.struct8-engine.name
  filter_group {
    filter {
      exclude_matched_pattern = false
      pattern                 = "WORKFLOW_JOB_QUEUED"
      type                    = "EVENT"
    }
  }
}


