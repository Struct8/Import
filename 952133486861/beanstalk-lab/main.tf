terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/beanstalk-lab/main.tfstate"
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

resource "aws_iam_instance_profile" "beanstalk-lab-web_profile" {
  name = "beanstalk-lab-web_profile"
  role = aws_iam_role.beanstalk-lab-web_role.name
  tags = {
    Name           = "beanstalk-lab-web_profile"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_iam_policy_document" "eb-debug_debug_permissions" {
  statement {
    sid       = "SendToTaggedInstancesOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      values   = ["iOhLcXismjKgeOkTBxnCY"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
  statement {
    sid       = "PinnedDocumentOnly"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/Struct8Probe-iOhLcXismjKgeOkTBxnCY"]
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
      values   = ["iOhLcXismjKgeOkTBxnCY"]
      variable = "aws:ResourceTag/Struct8Debug"
    }
  }
}

data "aws_iam_policy_document" "eb-debug_debug_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountStruct8"]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "Struct8Debug-eb-debug" {
  name                 = "Struct8Debug-iOhLcXismjKgeOkTBxnCY"
  assume_role_policy   = data.aws_iam_policy_document.eb-debug_debug_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "beanstalk-lab-web_role" {
  name = "beanstalk-lab-web_role"
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
    Name           = "beanstalk-lab-web_role"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy" "Struct8Debug-eb-debug_policy" {
  name   = "Struct8Debug-iOhLcXismjKgeOkTBxnCY-policy"
  policy = data.aws_iam_policy_document.eb-debug_debug_permissions.json
  role   = aws_iam_role.Struct8Debug-eb-debug.id
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkMulticontainerDocker_to_beanstalk-lab-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  role       = aws_iam_role.beanstalk-lab-web_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWebTier_to_beanstalk-lab-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.beanstalk-lab-web_role.name
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkWorkerTier_to_beanstalk-lab-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
  role       = aws_iam_role.beanstalk-lab-web_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore_to_beanstalk-lab-web_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.beanstalk-lab-web_role.name
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "vpc-beanstalk-lab" {
  cidr_block           = "10.40.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "vpc-beanstalk-lab"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "eb-app-a" {
  vpc_id                  = aws_vpc.vpc-beanstalk-lab.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.40.10.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "eb-app-a"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "eb-app-b" {
  vpc_id                  = aws_vpc.vpc-beanstalk-lab.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.40.11.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "eb-app-b"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "eb-public-a" {
  vpc_id                  = aws_vpc.vpc-beanstalk-lab.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.40.0.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "eb-public-a"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "eb-public-b" {
  vpc_id                  = aws_vpc.vpc-beanstalk-lab.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.40.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "eb-public-b"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-beanstalk-lab" {
  vpc_id = aws_vpc.vpc-beanstalk-lab.id
  tags = {
    Name           = "igw-beanstalk-lab"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_nat_gateway" "nat-beanstalk-lab" {
  vpc_id            = aws_vpc.vpc-beanstalk-lab.id
  availability_mode = "regional"
  connectivity_type = "public"
  tags = {
    Name           = "nat-beanstalk-lab"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_internet_gateway.igw-beanstalk-lab]
}

resource "aws_route" "route_rt-private-eb_to_nat-beanstalk-lab_ipv4" {
  nat_gateway_id         = aws_nat_gateway.nat-beanstalk-lab.id
  route_table_id         = aws_route_table.rt-private-eb.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public-eb_to_igw-beanstalk-lab_ipv4" {
  gateway_id             = aws_internet_gateway.igw-beanstalk-lab.id
  route_table_id         = aws_route_table.rt-public-eb.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-private-eb" {
  vpc_id = aws_vpc.vpc-beanstalk-lab.id
  tags = {
    Name           = "rt-private-eb"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-public-eb" {
  vpc_id = aws_vpc.vpc-beanstalk-lab.id
  tags = {
    Name           = "rt-public-eb"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_eb_app_a_rt_private_eb" {
  route_table_id = aws_route_table.rt-private-eb.id
  subnet_id      = aws_subnet.eb-app-a.id
}

resource "aws_route_table_association" "aws_route_table_association_eb_app_b_rt_private_eb" {
  route_table_id = aws_route_table.rt-private-eb.id
  subnet_id      = aws_subnet.eb-app-b.id
}

resource "aws_route_table_association" "aws_route_table_association_eb_public_a_rt_public_eb" {
  route_table_id = aws_route_table.rt-public-eb.id
  subnet_id      = aws_subnet.eb-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_eb_public_b_rt_public_eb" {
  route_table_id = aws_route_table.rt-public-eb.id
  subnet_id      = aws_subnet.eb-public-b.id
}

resource "aws_security_group" "elastic_beanstalk_environment_beanstalk-lab-web_group" {
  name                   = "elastic_beanstalk_environment_beanstalk-lab-web_group"
  vpc_id                 = aws_vpc.vpc-beanstalk-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "elastic_beanstalk_environment_beanstalk-lab-web_group"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_elastic_beanstalk_environment_beanstalk_lab_web_group_egress_all_protocols" {
  security_group_id = aws_security_group.elastic_beanstalk_environment_beanstalk-lab-web_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: COMPUTE ###

resource "aws_elastic_beanstalk_application" "beanstalk-lab" {
  name = "beanstalk-lab"
  tags = {
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_elastic_beanstalk_environment" "beanstalk-lab-web" {
  name                   = "beanstalk-lab-web"
  solution_stack_name    = "64bit Amazon Linux 2023 v6.12.0 running Node.js 22"
  application            = aws_elastic_beanstalk_application.beanstalk-lab.name
  wait_for_ready_timeout = "20m"
  setting {
    name      = "NAME"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-lab-web"
  }
  setting {
    name      = "REGION"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_region.current.region}"
  }
  setting {
    name      = "ACCOUNT"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_caller_identity.current.account_id}"
  }
  setting {
    name      = "AWS_ELASTIC_BEANSTALK_APPLICATION_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-lab"
  }
  setting {
    name      = "VPCId"
    namespace = "aws:ec2:vpc"
    value     = aws_vpc.vpc-beanstalk-lab.id
  }
  setting {
    name      = "Subnets"
    namespace = "aws:ec2:vpc"
    value     = "${aws_subnet.eb-app-a.id},${aws_subnet.eb-app-b.id}"
  }
  setting {
    name      = "ELBSubnets"
    namespace = "aws:ec2:vpc"
    value     = "${aws_subnet.eb-public-a.id},${aws_subnet.eb-public-b.id}"
  }
  setting {
    name      = "EnvironmentType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "LoadBalanced"
  }
  setting {
    name      = "InstanceTypes"
    namespace = "aws:ec2:instances"
    value     = "t4g.nano"
  }
  setting {
    name      = "SupportedArchitectures"
    namespace = "aws:ec2:instances"
    value     = "arm64"
  }
  setting {
    name      = "LoadBalancerType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "classic"
  }
  setting {
    name      = "MinSize"
    namespace = "aws:autoscaling:asg"
    value     = "1"
  }
  setting {
    name      = "MaxSize"
    namespace = "aws:autoscaling:asg"
    value     = "1"
  }
  setting {
    name      = "SystemType"
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    value     = "enhanced"
  }
  setting {
    name      = "ConfigDocument"
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    value     = jsonencode({ Version = 1, CloudWatchMetrics = { Environment = { InstancesOk = 60 } } })
  }
  setting {
    name      = "SecurityGroups"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_security_group.elastic_beanstalk_environment_beanstalk-lab-web_group.id
  }
  setting {
    name      = "IamInstanceProfile"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_iam_instance_profile.beanstalk-lab-web_profile.name
  }
  tags = {
    Struct8Debug   = "iOhLcXismjKgeOkTBxnCY"
    State          = "beanstalk-lab"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: CONFIG ###

resource "aws_ssm_document" "Struct8Probe-eb-debug" {
  name = "Struct8Probe-iOhLcXismjKgeOkTBxnCY"
  content = <<EOF
{
  "schemaVersion": "2.2",
  "description": "Struct8 network probe. The command text is fixed here; the caller supplies only a target and a port.",
  "parameters": {
    "target": {
      "type": "String",
      "description": "Hostname or IP address to probe.",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[A-Za-z0-9._-]{1,253}$"
    },
    "port": {
      "type": "String",
      "description": "TCP port to test.",
      "default": "443",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[0-9]{1,5}$"
    }
  },
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "struct8Probe",
      "inputs": {
        "timeoutSeconds": "60",
        "runCommand": [
          "if [ -z \"$SSM_target\" ]; then export SSM_target=\"{{target}}\"; fi",
          "if [ -z \"$SSM_port\" ]; then export SSM_port=\"{{port}}\"; fi",
          "echo '--- resolve ---'",
          "getent hosts \"$SSM_target\" || echo \"no DNS answer\"",
          "echo '--- icmp ---'",
          "ping -c 3 -W 2 \"$SSM_target\" || echo \"no ICMP reply (often filtered, not conclusive)\"",
          "echo '--- tcp ---'",
          "if timeout 5 bash -c 'exec 3<>/dev/tcp/\"$1\"/\"$2\"' _ \"$SSM_target\" \"$SSM_port\" 2>/dev/null; then echo \"port $SSM_port open\"; else echo \"port $SSM_port closed or filtered\"; fi"
        ]
      }
    }
  ]
}
  EOF
  document_format = "JSON"
  document_type   = "Command"
}


