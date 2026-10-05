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
    key     = "952133486861/demo-aurora-state/main.tfstate"
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

resource "aws_iam_instance_profile" "demo-pgweb_profile" {
  name = "demo-pgweb_profile"
  role = aws_iam_role.demo-pgweb_role.name
  tags = {
    Name           = "demo-pgweb_profile"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "db_proxy_demo-aurora-rds-proxy_st_demo-aurora-state_doc" {
  statement {
    sid       = "ReadDatabaseCredentials"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [one(aws_rds_cluster.demo-aurora.master_user_secret[*].secret_arn)]
  }
}

resource "aws_iam_policy" "db_proxy_demo-aurora-rds-proxy_st_demo-aurora-state" {
  name        = "db_proxy_demo-aurora-rds-proxy_st_demo-aurora-state"
  description = "Access Policy for demo-aurora-rds-proxy"
  policy      = data.aws_iam_policy_document.db_proxy_demo-aurora-rds-proxy_st_demo-aurora-state_doc.json
}

data "aws_iam_policy_document" "instance_demo-pgweb_st_demo-aurora-state_doc" {
  statement {
    sid       = "AllowRDSDataApidemoaurora"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.demo-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessdemoaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.demo-aurora.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "instance_demo-pgweb_st_demo-aurora-state" {
  name        = "instance_demo-pgweb_st_demo-aurora-state"
  description = "Access Policy for demo-pgweb"
  policy      = data.aws_iam_policy_document.instance_demo-pgweb_st_demo-aurora-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_demo-aurora-dataapi_st_demo-aurora-state_doc" {
  statement {
    sid       = "AllowRDSDataApidemoaurora"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.demo-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessdemoaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.demo-aurora.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "lambda_function_demo-aurora-dataapi_st_demo-aurora-state" {
  name        = "lambda_function_demo-aurora-dataapi_st_demo-aurora-state"
  description = "Access Policy for demo-aurora-dataapi"
  policy      = data.aws_iam_policy_document.lambda_function_demo-aurora-dataapi_st_demo-aurora-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_demo-aurora-direct_st_demo-aurora-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.demo-aurora-direct-logs.arn}:*"]
  }
  statement {
    sid       = "AllowRDSDataApidemoaurora"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.demo-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessdemoaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.demo-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowAllResources"
    effect    = "Allow"
    actions   = ["ec2:AssignPrivateIpAddresses", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:UnassignPrivateIpAddresses"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_function_demo-aurora-direct_st_demo-aurora-state" {
  name        = "lambda_function_demo-aurora-direct_st_demo-aurora-state"
  description = "Access Policy for demo-aurora-direct"
  policy      = data.aws_iam_policy_document.lambda_function_demo-aurora-direct_st_demo-aurora-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_demo-aurora-iam_st_demo-aurora-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.demo-aurora-iam-logs.arn}:*"]
  }
  statement {
    sid       = "AllowRDSDataApidemoaurora"
    effect    = "Allow"
    actions   = ["rds-data:BatchExecuteStatement", "rds-data:BeginTransaction", "rds-data:CommitTransaction", "rds-data:ExecuteStatement", "rds-data:RollbackTransaction"]
    resources = [aws_rds_cluster.demo-aurora.arn]
  }
  statement {
    sid       = "AllowRDSSecretAccessdemoaurora"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.demo-aurora.master_user_secret[0].secret_arn]
  }
  statement {
    sid       = "AllowAllResources"
    effect    = "Allow"
    actions   = ["ec2:AssignPrivateIpAddresses", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:UnassignPrivateIpAddresses"]
    resources = ["*"]
  }
  statement {
    sid       = "RdsIamConnect"
    effect    = "Allow"
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster.demo-aurora.cluster_resource_id}/lambda_iam"]
  }
}

resource "aws_iam_policy" "lambda_function_demo-aurora-iam_st_demo-aurora-state" {
  name        = "lambda_function_demo-aurora-iam_st_demo-aurora-state"
  description = "Access Policy for demo-aurora-iam"
  policy      = data.aws_iam_policy_document.lambda_function_demo-aurora-iam_st_demo-aurora-state_doc.json
}

data "aws_iam_policy_document" "lambda_function_demo-aurora-proxy_st_demo-aurora-state_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.demo-aurora-proxy-logs.arn}:*"]
  }
  statement {
    sid       = "ReadDatabaseCredentials"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [one(aws_rds_cluster.demo-aurora.master_user_secret[*].secret_arn)]
  }
  statement {
    sid       = "AllowAllResources"
    effect    = "Allow"
    actions   = ["ec2:AssignPrivateIpAddresses", "ec2:CreateNetworkInterface", "ec2:DeleteNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:UnassignPrivateIpAddresses"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_function_demo-aurora-proxy_st_demo-aurora-state" {
  name        = "lambda_function_demo-aurora-proxy_st_demo-aurora-state"
  description = "Access Policy for demo-aurora-proxy"
  policy      = data.aws_iam_policy_document.lambda_function_demo-aurora-proxy_st_demo-aurora-state_doc.json
}

data "aws_iam_policy_document" "Debug_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["n2L5m9CkjzH7IUewAgbOZ"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
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
      values   = ["n2L5m9CkjzH7IUewAgbOZ"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "RunShellScriptDocument"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*::document/AWS-RunShellScript"]
  }
}

data "aws_iam_policy_document" "Debug_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-Debug" {
  name                 = "Struct8Debug-n2L5m9CkjzH7IUewAgbOZ"
  assume_role_policy   = data.aws_iam_policy_document.Debug_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "demo-aurora-dataapi_role" {
  name = "demo-aurora-dataapi_role"
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
    Name           = "demo-aurora-dataapi_role"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-aurora-direct_role" {
  name = "demo-aurora-direct_role"
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
    Name           = "demo-aurora-direct_role"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-aurora-iam_role" {
  name = "demo-aurora-iam_role"
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
    Name           = "demo-aurora-iam_role"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-aurora-proxy_role" {
  name = "demo-aurora-proxy_role"
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
    Name           = "demo-aurora-proxy_role"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "demo-pgweb_role" {
  name = "demo-pgweb_role"
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
    Name           = "demo-pgweb_role"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_rds_proxy_demo-aurora-rds-proxy" {
  name = "role_rds_proxy_demo-aurora-rds-proxy"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "role_rds_proxy_demo-aurora-rds-proxy"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-Debug_policy" {
  name   = "Struct8Debug-n2L5m9CkjzH7IUewAgbOZ-policy"
  policy = data.aws_iam_policy_document.Debug_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-Debug.id
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_demo-pgweb_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.demo-pgweb_role.name
}

resource "aws_iam_role_policy_attachment" "db_proxy_demo-aurora-rds-proxy_st_demo-aurora-state_attach" {
  policy_arn = aws_iam_policy.db_proxy_demo-aurora-rds-proxy_st_demo-aurora-state.arn
  role       = aws_iam_role.role_rds_proxy_demo-aurora-rds-proxy.name
}

resource "aws_iam_role_policy_attachment" "instance_demo-pgweb_st_demo-aurora-state_attach" {
  policy_arn = aws_iam_policy.instance_demo-pgweb_st_demo-aurora-state.arn
  role       = aws_iam_role.demo-pgweb_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_demo-aurora-dataapi_st_demo-aurora-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_demo-aurora-dataapi_st_demo-aurora-state.arn
  role       = aws_iam_role.demo-aurora-dataapi_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_demo-aurora-direct_st_demo-aurora-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_demo-aurora-direct_st_demo-aurora-state.arn
  role       = aws_iam_role.demo-aurora-direct_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_demo-aurora-iam_st_demo-aurora-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_demo-aurora-iam_st_demo-aurora-state.arn
  role       = aws_iam_role.demo-aurora-iam_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_function_demo-aurora-proxy_st_demo-aurora-state_attach" {
  policy_arn = aws_iam_policy.lambda_function_demo-aurora-proxy_st_demo-aurora-state.arn
  role       = aws_iam_role.demo-aurora-proxy_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "aurora-access-patterns-lab" {
  cidr_block           = "10.8.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "aurora-access-patterns-lab"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "ep-cloudwatch_LOGS" {
  service_name        = "com.amazonaws.${data.aws_region.current.region}.logs"
  vpc_id              = aws_vpc.aurora-access-patterns-lab.id
  ip_address_type     = "ipv4"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_vpce_ep-cloudwatch.id]
  subnet_ids          = [aws_subnet.demo-aurora-private-b.id, aws_subnet.demo-aurora-private-a.id]
  vpc_endpoint_type   = "Interface"
  tags = {
    Name           = "ep-cloudwatch"
    DifName        = "ep-cloudwatch_LOGS"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "ep-secret-manager_SECRETSMANAGER" {
  service_name        = "com.amazonaws.${data.aws_region.current.region}.secretsmanager"
  vpc_id              = aws_vpc.aurora-access-patterns-lab.id
  ip_address_type     = "ipv4"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_vpce_ep-secret-manager.id]
  subnet_ids          = [aws_subnet.demo-aurora-private-b.id, aws_subnet.demo-aurora-private-a.id]
  vpc_endpoint_type   = "Interface"
  tags = {
    Name           = "ep-secret-manager"
    DifName        = "ep-secret-manager_SECRETSMANAGER"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-aurora-private-a" {
  vpc_id                  = aws_vpc.aurora-access-patterns-lab.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.8.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-aurora-private-a"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-aurora-private-b" {
  vpc_id                  = aws_vpc.aurora-access-patterns-lab.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.8.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "demo-aurora-private-b"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "demo-public-a" {
  vpc_id                  = aws_vpc.aurora-access-patterns-lab.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.8.10.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "demo-public-a"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.aurora-access-patterns-lab.id
  tags = {
    Name           = "demo-igw"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_demo-public-rt_to_demo-igw_ipv4" {
  gateway_id             = aws_internet_gateway.demo-igw.id
  route_table_id         = aws_route_table.demo-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "demo-public-rt" {
  vpc_id = aws_vpc.aurora-access-patterns-lab.id
  tags = {
    Name           = "demo-public-rt"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_demo_public_a_demo_public_rt" {
  route_table_id = aws_route_table.demo-public-rt.id
  subnet_id      = aws_subnet.demo-public-a.id
}

resource "aws_security_group" "db_proxy_demo-aurora-rds-proxy_group" {
  name                   = "db_proxy_demo-aurora-rds-proxy_group"
  vpc_id                 = aws_vpc.aurora-access-patterns-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "db_proxy_demo-aurora-rds-proxy_group"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "demo-aurora-direct" {
  name                   = "demo-aurora-direct"
  vpc_id                 = aws_vpc.aurora-access-patterns-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "demo-aurora-direct"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "demo-aurora-iam" {
  name                   = "demo-aurora-iam"
  vpc_id                 = aws_vpc.aurora-access-patterns-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "demo-aurora-iam"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "demo-aurora-proxy" {
  name                   = "demo-aurora-proxy"
  vpc_id                 = aws_vpc.aurora-access-patterns-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "demo-aurora-proxy"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_demo-pgweb_group" {
  name                   = "instance_demo-pgweb_group"
  vpc_id                 = aws_vpc.aurora-access-patterns-lab.id
  description            = "pgweb web UI"
  revoke_rules_on_delete = false
}

resource "aws_security_group" "rds_cluster_demo-aurora_group" {
  name                   = "rds_cluster_demo-aurora_group"
  vpc_id                 = aws_vpc.aurora-access-patterns-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "rds_cluster_demo-aurora_group"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "sg_vpce_ep-cloudwatch" {
  name        = "vpce-sg-ep-cloudwatch"
  vpc_id      = aws_vpc.aurora-access-patterns-lab.id
  description = "Auto-generated SG for ep-cloudwatch"
  tags = {
    Name           = "ep-cloudwatch"
    DifName        = "sg_vpce_ep-cloudwatch"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "sg_vpce_ep-secret-manager" {
  name        = "vpce-sg-ep-secret-manager"
  vpc_id      = aws_vpc.aurora-access-patterns-lab.id
  description = "Auto-generated SG for ep-secret-manager"
  tags = {
    Name           = "ep-secret-manager"
    DifName        = "sg_vpce_ep-secret-manager"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_db_proxy_demo_aurora_rds_proxy_group_egress_all_protocols" {
  security_group_id = aws_security_group.db_proxy_demo-aurora-rds-proxy_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_db_proxy_demo_aurora_rds_proxy_group_to_rds_cluster_demo_aurora_group_tcp_5432" {
  security_group_id        = aws_security_group.rds_cluster_demo-aurora_group.id
  source_security_group_id = aws_security_group.db_proxy_demo-aurora-rds-proxy_group.id
  description              = "Allow from RDS Proxy demo-aurora-rds-proxy"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_demo_aurora_direct_egress_all_protocols" {
  security_group_id = aws_security_group.demo-aurora-direct.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_demo_aurora_direct_to_rds_cluster_demo_aurora_group_tcp_5432" {
  security_group_id        = aws_security_group.rds_cluster_demo-aurora_group.id
  source_security_group_id = aws_security_group.demo-aurora-direct.id
  description              = "Allow from demo-aurora-direct (tcp:5432-5432)"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_demo_aurora_iam_egress_all_protocols" {
  security_group_id = aws_security_group.demo-aurora-iam.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_demo_aurora_iam_to_rds_cluster_demo_aurora_group_tcp_5432" {
  security_group_id        = aws_security_group.rds_cluster_demo-aurora_group.id
  source_security_group_id = aws_security_group.demo-aurora-iam.id
  description              = "Allow from demo-aurora-iam (tcp:5432-5432)"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_demo_aurora_proxy_egress_all_protocols" {
  security_group_id = aws_security_group.demo-aurora-proxy.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_demo_aurora_proxy_to_db_proxy_demo_aurora_rds_proxy_group_tcp_5432" {
  security_group_id        = aws_security_group.db_proxy_demo-aurora-rds-proxy_group.id
  source_security_group_id = aws_security_group.demo-aurora-proxy.id
  description              = "Allow from demo-aurora-proxy (tcp:5432-5432)"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_instance_demo_pgweb_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_demo-pgweb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_demo_pgweb_group_ingress_tcp_8081" {
  security_group_id = aws_security_group.instance_demo-pgweb_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8081
  protocol          = "tcp"
  to_port           = 8081
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_demo_pgweb_group_to_rds_cluster_demo_aurora_group_tcp_5432" {
  security_group_id        = aws_security_group.rds_cluster_demo-aurora_group.id
  source_security_group_id = aws_security_group.instance_demo-pgweb_group.id
  description              = "Allow from instance_demo-pgweb_group (tcp:5432-5432)"
  from_port                = 5432
  protocol                 = "tcp"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_rds_cluster_demo_aurora_group_egress_all_protocols" {
  security_group_id = aws_security_group.rds_cluster_demo-aurora_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_sg_vpce_ep_cloudwatch_egress_all_protocols" {
  security_group_id = aws_security_group.sg_vpce_ep-cloudwatch.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_sg_vpce_ep_cloudwatch_ingress_tcp_443" {
  security_group_id = aws_security_group.sg_vpce_ep-cloudwatch.id
  cidr_blocks       = ["10.8.0.0/16"]
  description       = "Allow HTTPS from VPC"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_sg_vpce_ep_secret_manager_egress_all_protocols" {
  security_group_id = aws_security_group.sg_vpce_ep-secret-manager.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_sg_vpce_ep_secret_manager_ingress_tcp_443" {
  security_group_id = aws_security_group.sg_vpce_ep-secret-manager.id
  cidr_blocks       = ["10.8.0.0/16"]
  description       = "Allow HTTPS from VPC"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}




### CATEGORY: DATABASE ###

resource "aws_db_proxy" "demo-aurora-rds-proxy" {
  name                   = "demo-aurora-rds-proxy"
  engine_family          = "POSTGRESQL"
  require_tls            = true
  role_arn               = aws_iam_role.role_rds_proxy_demo-aurora-rds-proxy.arn
  vpc_security_group_ids = [aws_security_group.db_proxy_demo-aurora-rds-proxy_group.id]
  vpc_subnet_ids         = [aws_subnet.demo-aurora-private-a.id, aws_subnet.demo-aurora-private-b.id]
  auth {
    auth_scheme               = "SECRETS"
    client_password_auth_type = "POSTGRES_SCRAM_SHA_256"
    iam_auth                  = "DISABLED"
    secret_arn                = one(aws_rds_cluster.demo-aurora.master_user_secret[*].secret_arn)
  }
  tags = {
    Name           = "demo-aurora-rds-proxy"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_cloudwatch_log_group.LogGroup, aws_iam_role_policy_attachment.db_proxy_demo-aurora-rds-proxy_st_demo-aurora-state_attach]
}

resource "aws_db_proxy_target" "demo-aurora-rds-proxy_target" {
  db_proxy_name         = aws_db_proxy.demo-aurora-rds-proxy.name
  target_group_name     = "default"
  db_cluster_identifier = aws_rds_cluster.demo-aurora.cluster_identifier
}

resource "aws_db_subnet_group" "subnet_group_demo-aurora" {
  name       = "demo-aurora-subnet-group"
  subnet_ids = [aws_subnet.demo-aurora-private-a.id]
  tags = {
    Name           = "subnet_group_demo-aurora"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster" "demo-aurora" {
  database_name                       = "appdb"
  db_subnet_group_name                = aws_db_subnet_group.subnet_group_demo-aurora.name
  apply_immediately                   = true
  backup_retention_period             = 7
  cluster_identifier                  = "demo-aurora"
  copy_tags_to_snapshot               = true
  database_insights_mode              = "standard"
  enable_http_endpoint                = true
  engine                              = "aurora-postgresql"
  engine_version                      = "16.6"
  iam_database_authentication_enabled = true
  manage_master_user_password         = true
  master_username                     = "dbadmin"
  monitoring_interval                 = 0
  network_type                        = "IPV4"
  port                                = 5432
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  vpc_security_group_ids              = [aws_security_group.rds_cluster_demo-aurora_group.id]
  serverlessv2_scaling_configuration {
    max_capacity = 2
    min_capacity = 0.5
  }
  tags = {
    Name           = "demo-aurora"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "demo-aurora-1" {
  cluster_identifier                    = aws_rds_cluster.demo-aurora.id
  copy_tags_to_snapshot                 = true
  engine                                = aws_rds_cluster.demo-aurora.engine
  identifier                            = "demo-aurora-1"
  instance_class                        = "db.serverless"
  performance_insights_retention_period = 7
  promotion_tier                        = 1
  tags = {
    Name           = "demo-aurora-1"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: COMPUTE ###

data "local_file" "UserData_demo-pgweb" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/ec2-pgweb-aurora/v1/user_data/pgweb-aurora.sh"
}

data "aws_ami" "AMI_Data_Source_demo-pgweb" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "demo-pgweb" {
  # ajuste manual · user_data_base64 — Generator bug: EC2 user_data env-var path escapes the string literal inside coalesce(...,"postgres") as \"postgres\", which is invalid HCL inside a ${} interpolation and breaks terraform plan. database_name is always set (appdb), so reference it directly without the coalesce fallback. Remove when the generator stops escaping quotes in the EC2 env block.
  subnet_id                   = aws_subnet.demo-public-a.id
  ami                         = data.aws_ami.AMI_Data_Source_demo-pgweb.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.demo-pgweb_profile.name
  instance_type               = "t3.small"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME="demo-pgweb"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
AWS_RDS_CLUSTER_NAME_0="${aws_rds_cluster.demo-aurora.cluster_identifier}"
AWS_RDS_CLUSTER_ENGINE_0="${aws_rds_cluster.demo-aurora.engine}"
AWS_RDS_CLUSTER_ENDPOINT_0="${aws_rds_cluster.demo-aurora.endpoint}"
AWS_RDS_CLUSTER_PORT_0="${aws_rds_cluster.demo-aurora.port}"
AWS_RDS_CLUSTER_DB_NAME_0="${aws_rds_cluster.demo-aurora.database_name}"
AWS_RDS_CLUSTER_SECRET_ARN_0="${one(aws_rds_cluster.demo-aurora.master_user_secret[*].secret_arn)}"
AWS_RDS_CLUSTER_ARN_0="${aws_rds_cluster.demo-aurora.arn}"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_demo-pgweb.content}
EOFUData
)
  vpc_security_group_ids = [aws_security_group.instance_demo-pgweb_group.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Struct8Debug   = "n2L5m9CkjzH7IUewAgbOZ"
    Name           = "demo-pgweb"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_struct8-hub_demo-aurora-dataapi" {
  output_path = "${path.module}/struct8-hub_demo-aurora-dataapi.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "demo-aurora-dataapi" {
  function_name                  = "demo-aurora-dataapi"
  architectures                  = ["arm64"]
  description                    = "Lambda OUTSIDE the VPC that writes via the Aurora Data API (HTTP + SigV4), running the Struct8 Hub"
  filename                       = data.archive_file.archive_struct8-hub_demo-aurora-dataapi.output_path
  handler                        = "index.handler"
  memory_size                    = 2000
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.demo-aurora-dataapi_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_demo-aurora-dataapi.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "demo-aurora-dataapi"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.demo-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.demo-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.demo-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.demo-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.demo-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.demo-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.demo-aurora.arn
    AWS_RDS_CLUSTER_DATA_API_0   = true
  }
  }
  tags = {
    Name           = "demo-aurora-dataapi"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_demo-aurora-dataapi_st_demo-aurora-state_attach]
}

data "archive_file" "archive_struct8-hub_demo-aurora-direct" {
  output_path = "${path.module}/struct8-hub_demo-aurora-direct.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "demo-aurora-direct" {
  function_name                  = "demo-aurora-direct"
  architectures                  = ["arm64"]
  description                    = "Reaches the Aurora cluster DIRECTLY (writer endpoint, no proxy), running the Struct8 Hub"
  filename                       = data.archive_file.archive_struct8-hub_demo-aurora-direct.output_path
  handler                        = "index.handler"
  memory_size                    = 2000
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.demo-aurora-direct_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_demo-aurora-direct.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "demo-aurora-direct"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.demo-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.demo-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.demo-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.demo-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.demo-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.demo-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.demo-aurora.arn
  }
  }
  tags = {
    Name           = "demo-aurora-direct"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
  vpc_config {
    security_group_ids = [aws_security_group.demo-aurora-direct.id]
    subnet_ids         = [aws_subnet.demo-aurora-private-a.id, aws_subnet.demo-aurora-private-b.id]
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_demo-aurora-direct_st_demo-aurora-state_attach]
}

data "archive_file" "archive_struct8-hub_demo-aurora-iam" {
  output_path = "${path.module}/struct8-hub_demo-aurora-iam.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "demo-aurora-iam" {
  function_name                  = "demo-aurora-iam"
  architectures                  = ["arm64"]
  description                    = "Reaches the Aurora cluster with IAM DATABASE AUTH (short-lived token, no stored password), running the Struct8 Hub"
  filename                       = data.archive_file.archive_struct8-hub_demo-aurora-iam.output_path
  handler                        = "index.handler"
  memory_size                    = 2000
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.demo-aurora-iam_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_demo-aurora-iam.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "demo-aurora-iam"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_RDS_CLUSTER_NAME_0       = aws_rds_cluster.demo-aurora.cluster_identifier
    AWS_RDS_CLUSTER_ENGINE_0     = aws_rds_cluster.demo-aurora.engine
    AWS_RDS_CLUSTER_ENDPOINT_0   = aws_rds_cluster.demo-aurora.endpoint
    AWS_RDS_CLUSTER_PORT_0       = aws_rds_cluster.demo-aurora.port
    AWS_RDS_CLUSTER_DB_NAME_0    = coalesce(aws_rds_cluster.demo-aurora.database_name, "postgres")
    AWS_RDS_CLUSTER_SECRET_ARN_0 = one(aws_rds_cluster.demo-aurora.master_user_secret[*].secret_arn)
    AWS_RDS_CLUSTER_ARN_0        = aws_rds_cluster.demo-aurora.arn
    AWS_RDS_CLUSTER_IAM_USER_0   = "lambda_iam"
  }
  }
  tags = {
    Name           = "demo-aurora-iam"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
  vpc_config {
    security_group_ids = [aws_security_group.demo-aurora-iam.id]
    subnet_ids         = [aws_subnet.demo-aurora-private-a.id, aws_subnet.demo-aurora-private-b.id]
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_demo-aurora-iam_st_demo-aurora-state_attach]
}

data "archive_file" "archive_struct8-hub_demo-aurora-proxy" {
  output_path = "${path.module}/struct8-hub_demo-aurora-proxy.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "demo-aurora-proxy" {
  function_name                  = "demo-aurora-proxy"
  architectures                  = ["arm64"]
  description                    = "Reaches the Aurora cluster THROUGH THE RDS PROXY (connection pooling), running the Struct8 Hub"
  filename                       = data.archive_file.archive_struct8-hub_demo-aurora-proxy.output_path
  handler                        = "index.handler"
  memory_size                    = 2000
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.demo-aurora-proxy_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_demo-aurora-proxy.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME                         = "demo-aurora-proxy"
    REGION                       = data.aws_region.current.region
    ACCOUNT                      = data.aws_caller_identity.current.account_id
    AWS_DB_PROXY_NAME_0          = aws_db_proxy.demo-aurora-rds-proxy.name
    AWS_DB_PROXY_ENDPOINT_0      = aws_db_proxy.demo-aurora-rds-proxy.endpoint
    AWS_DB_PROXY_PORT_0          = "5432"
    AWS_DB_PROXY_ENGINE_FAMILY_0 = "POSTGRESQL"
    AWS_DB_PROXY_SECRET_ARN_0    = tolist(aws_db_proxy.demo-aurora-rds-proxy.auth)[0].secret_arn
    AWS_DB_PROXY_DB_NAME_0       = "appdb"
  }
  }
  tags = {
    Name           = "demo-aurora-proxy"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
  vpc_config {
    security_group_ids = [aws_security_group.demo-aurora-proxy.id]
    subnet_ids         = [aws_subnet.demo-aurora-private-a.id, aws_subnet.demo-aurora-private-b.id]
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_demo-aurora-proxy_st_demo-aurora-state_attach]
}

resource "aws_lambda_permission" "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-dataapi" {
  function_name = aws_lambda_function.demo-aurora-dataapi.function_name
  statement_id  = "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-dataapi"
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_cloudwatch_event_rule.every-1-minute.arn
}

resource "aws_lambda_permission" "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-direct" {
  function_name = aws_lambda_function.demo-aurora-direct.function_name
  statement_id  = "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-direct"
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_cloudwatch_event_rule.every-1-minute.arn
}

resource "aws_lambda_permission" "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-iam" {
  function_name = aws_lambda_function.demo-aurora-iam.function_name
  statement_id  = "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-iam"
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_cloudwatch_event_rule.every-1-minute.arn
}

resource "aws_lambda_permission" "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-proxy" {
  function_name = aws_lambda_function.demo-aurora-proxy.function_name
  statement_id  = "perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-proxy"
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  source_arn    = aws_cloudwatch_event_rule.every-1-minute.arn
}




### CATEGORY: INTEGRATION ###

resource "aws_cloudwatch_event_rule" "every-1-minute" {
  name                = "every-1-minute"
  schedule_expression = "rate(1 minute)"
  state               = "ENABLED"
  tags = {
    Name           = "every-1-minute"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_event_target" "Target" {
  arn        = aws_lambda_function.demo-aurora-direct.arn
  rule       = aws_cloudwatch_event_rule.every-1-minute.name
  depends_on = [aws_lambda_permission.perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-direct]
}

resource "aws_cloudwatch_event_target" "Target1" {
  arn        = aws_lambda_function.demo-aurora-proxy.arn
  rule       = aws_cloudwatch_event_rule.every-1-minute.name
  depends_on = [aws_lambda_permission.perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-proxy]
}

resource "aws_cloudwatch_event_target" "Target2" {
  arn        = aws_lambda_function.demo-aurora-iam.arn
  rule       = aws_cloudwatch_event_rule.every-1-minute.name
  depends_on = [aws_lambda_permission.perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-iam]
}

resource "aws_cloudwatch_event_target" "Target3" {
  arn        = aws_lambda_function.demo-aurora-dataapi.arn
  rule       = aws_cloudwatch_event_rule.every-1-minute.name
  depends_on = [aws_lambda_permission.perm_aws_cloudwatch_event_rule_every-1-minute_to_demo-aurora-dataapi]
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "LogGroup" {
  name              = "/aws/rds/proxy/demo-aurora-rds-proxy"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "LogGroup"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "demo-aurora-direct-logs" {
  name              = "/aws/lambda/demo-postgres-direct"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "demo-aurora-direct-logs"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "demo-aurora-iam-logs" {
  name              = "/aws/lambda/demo-aurora-iam"
  log_group_class   = "STANDARD"
  retention_in_days = 30
  skip_destroy      = false
  tags = {
    Name           = "demo-aurora-iam-logs"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_log_group" "demo-aurora-proxy-logs" {
  name              = "/aws/lambda/demo-postgres-api"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "demo-aurora-proxy-logs"
    State          = "demo-aurora-state"
    Struct8Creator = "Contato Struct"
  }
}


