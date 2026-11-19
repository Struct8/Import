resource "aws_iam_instance_profile" "k6Generator_profile" {
  name = "k6Generator_profile"
  role = aws_iam_role.k6Generator_role.name
  tags = {
    Name           = "k6Generator_profile"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "synthetics_canary_wpReadCanary_st_wordpress-loadtest_doc" {
  statement {
    sid       = "AllowCanaryArtifactBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.canaryArtifacts.arn]
  }
  statement {
    sid       = "AllowCanaryArtifactObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.canaryArtifacts.arn}/*"]
  }
  statement {
    sid       = "CanaryMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
  }
  statement {
    sid       = "CanaryListBuckets"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
  statement {
    sid       = "CanaryLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwsyn-*:*"]
  }
}

resource "aws_iam_policy" "synthetics_canary_wpReadCanary_st_wordpress-loadtest" {
  name        = "synthetics_canary_wpReadCanary_st_wordpress-loadtest"
  description = "Access Policy for wpReadCanary"
  policy      = data.aws_iam_policy_document.synthetics_canary_wpReadCanary_st_wordpress-loadtest_doc.json
}

data "aws_iam_policy_document" "Debug1_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["2zeRq_EaN5iT0PSAbe6RL"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-2zeRq_EaN5iT0PSAbe6RL"]
  }
  statement {
    sid       = "ReadOwnResults"
    effect    = "Allow"
    actions   = ["ssm:GetCommandInvocation", "ssm:DescribeInstanceInformation"]
    resources = ["*"]
  }
  statement {
    sid       = "CancelOnTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:CancelCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["2zeRq_EaN5iT0PSAbe6RL"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "Debug1_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-Debug1" {
  name                 = "Struct8Debug-2zeRq_EaN5iT0PSAbe6RL"
  assume_role_policy   = data.aws_iam_policy_document.Debug1_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "k6Generator_role" {
  name = "k6Generator_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "k6Generator_role"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "wpReadCanary_role" {
  name = "wpReadCanary_role"
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
    Name           = "wpReadCanary_role"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-Debug1_policy" {
  name   = "Struct8Debug-2zeRq_EaN5iT0PSAbe6RL-policy"
  policy = data.aws_iam_policy_document.Debug1_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-Debug1.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_k6Generator_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.k6Generator_role.name
}

resource "aws_iam_role_policy_attachment" "synthetics_canary_wpReadCanary_st_wordpress-loadtest_attach" {
  policy_arn = aws_iam_policy.synthetics_canary_wpReadCanary_st_wordpress-loadtest.arn
  role       = aws_iam_role.wpReadCanary_role.name
}
