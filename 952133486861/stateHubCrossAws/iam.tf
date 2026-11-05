data "aws_iam_policy_document" "lambda_function_cross-caller_st_stateHubCrossAws_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.cross-caller-logs.arn}:*"]
  }
  statement {
    sid       = "AllowSendTracesToXRay"
    effect    = "Allow"
    actions   = ["xray:PutTelemetryRecords", "xray:PutTraceSegments"]
    resources = ["*"]
  }
  statement {
    sid       = "AllowReadCrossCloudKeys"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/cross-cloud/cross-link/google"]
  }
}

resource "aws_iam_policy" "lambda_function_cross-caller_st_stateHubCrossAws" {
  name        = "lambda_function_cross-caller_st_stateHubCrossAws"
  description = "Access Policy for cross-caller"
  policy      = data.aws_iam_policy_document.lambda_function_cross-caller_st_stateHubCrossAws_doc.json
}

resource "aws_iam_role" "cross-caller_role" {
  name = "cross-caller_role"
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
    Name           = "cross-caller_role"
    State          = "stateHubCrossAws"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_cross-caller_st_stateHubCrossAws_attach" {
  policy_arn = aws_iam_policy.lambda_function_cross-caller_st_stateHubCrossAws.arn
  role       = aws_iam_role.cross-caller_role.name
}
