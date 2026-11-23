data "aws_iam_policy_document" "lambda_function_r2-lab-fn_st_stateR2LabAws_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.r2-lab-fn-logs.arn}:*"]
  }
  statement {
    sid       = "AllowReadCrossCloudKeys"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/cross-cloud/r2lab/r2"]
  }
}

resource "aws_iam_policy" "lambda_function_r2-lab-fn_st_stateR2LabAws" {
  name        = "lambda_function_r2-lab-fn_st_stateR2LabAws"
  description = "Access Policy for r2-lab-fn"
  policy      = data.aws_iam_policy_document.lambda_function_r2-lab-fn_st_stateR2LabAws_doc.json
}

resource "aws_iam_role" "r2-lab-fn_role" {
  name = "r2-lab-fn_role"
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
    Name           = "r2-lab-fn_role"
    State          = "stateR2LabAws"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_r2-lab-fn_st_stateR2LabAws_attach" {
  policy_arn = aws_iam_policy.lambda_function_r2-lab-fn_st_stateR2LabAws.arn
  role       = aws_iam_role.r2-lab-fn_role.name
}
