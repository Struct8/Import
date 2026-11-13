data "aws_iam_policy_document" "workload_identity_wif-gcp-lab_st_stateWifGcpAws_doc" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.wif-gcp-lab-proof.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.wif-gcp-lab-proof.arn}/*"]
  }
}

resource "aws_iam_policy" "workload_identity_wif-gcp-lab_st_stateWifGcpAws" {
  name        = "workload_identity_wif-gcp-lab_st_stateWifGcpAws"
  description = "Access Policy for wif-gcp-lab"
  policy      = data.aws_iam_policy_document.workload_identity_wif-gcp-lab_st_stateWifGcpAws_doc.json
}

data "aws_iam_policy_document" "wif-gcp-lab_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["accounts.google.com"]
      type        = "Federated"
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "accounts.google.com:oaud"
    }
    condition {
      test     = "StringEquals"
      values   = ["wif-lab-job-sa@deft-landing-343414.iam.gserviceaccount.com"]
      variable = "accounts.google.com:email"
    }
  }
}

resource "aws_iam_role" "wif-gcp-lab" {
  name               = "wif-gcp-lab"
  assume_role_policy = data.aws_iam_policy_document.wif-gcp-lab_trust.json
  tags = {
    Name           = "wif-gcp-lab"
    State          = "stateWifGcpAws"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "workload_identity_wif-gcp-lab_st_stateWifGcpAws_attach" {
  policy_arn = aws_iam_policy.workload_identity_wif-gcp-lab_st_stateWifGcpAws.arn
  role       = aws_iam_role.wif-gcp-lab.name
}
