terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/Import-loop3/main.tfstate"
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

resource "aws_iam_openid_connect_provider" "token_actions_githubusercontent_com" {
  name = "token_actions_githubusercontent_com"
  tags = {
    Name           = "token_actions_githubusercontent_com"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "Struct8-Gitops-Struct8-import" {
  name                  = "Struct8-Gitops-Struct8-import"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRoleWithWebIdentity\",\"Condition\":{\"StringEquals\":{\"token.actions.githubusercontent.com:aud\":\"sts.amazonaws.com\"},\"StringEqualsIgnoreCase\":{\"token.actions.githubusercontent.com:sub\":[\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/devlocal\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/dev\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/test\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/alpha\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/engine.yml@refs/heads/main\",\"repo:Struct8@276103125/Import@1360758768:ref:refs/heads/main:job_workflow_ref:Struct8/cloudman-core/.github/workflows/lambda-sync.yml@refs/heads/main\"]}},\"Effect\":\"Allow\",\"Principal\":{\"Federated\":\"arn:aws:iam::952133486861:oidc-provider/token.actions.githubusercontent.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  inline_policy {
    name   = "Struct8ProtectOwnTrust"
    policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":[\"iam:UpdateAssumeRolePolicy\",\"iam:UpdateRole\",\"iam:DeleteRole\",\"iam:PutRolePolicy\",\"iam:DeleteRolePolicy\",\"iam:AttachRolePolicy\",\"iam:DetachRolePolicy\",\"iam:PutRolePermissionsBoundary\",\"iam:DeleteRolePermissionsBoundary\"],\"Effect\":\"Deny\",\"Resource\":\"arn:aws:iam::952133486861:role/Struct8-Gitops-Struct8-import\"},{\"Action\":[\"iam:DeleteOpenIDConnectProvider\",\"iam:UpdateOpenIDConnectProviderThumbprint\",\"iam:AddClientIDToOpenIDConnectProvider\",\"iam:RemoveClientIDFromOpenIDConnectProvider\"],\"Effect\":\"Deny\",\"Resource\":\"arn:aws:iam::952133486861:oidc-provider/token.actions.githubusercontent.com\"},{\"Action\":[\"cloudtrail:StopLogging\",\"cloudtrail:DeleteTrail\",\"cloudtrail:UpdateTrail\",\"cloudtrail:PutEventSelectors\"],\"Effect\":\"Deny\",\"Resource\":\"*\"}]}"
  }
  tags = {
    Name           = "Struct8-Gitops-Struct8-import"
    State          = "Struct8-Gitops-Struct8-import"
    Struct8User    = "Contato Struct"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "oregon-asg-vpc2" {
  assign_generated_ipv6_cidr_block     = true
  cidr_block                           = "10.30.0.0/16"
  enable_dns_support                   = true
  instance_tenancy                     = "default"
  ipv6_cidr_block_network_border_group = "us-west-2"
  tags = {
    Name           = "oregon-asg-vpc2"
    Project        = "oregon-asg"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc" "oregon-net-vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "oregon-net-vpc"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net-vpce-dynamodb_DynamoDB" {
  service_name      = "com.amazonaws.us-west-2.dynamodb"
  vpc_id            = aws_vpc.oregon-net-vpc.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net-rt-private-b.id, aws_route_table.oregon-net-rt-private-a.id, aws_route_table.oregon-net-rt-private-c.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    Name           = "oregon-net-vpce-dynamodb"
    Project        = "oregon-net"
    DifName        = "oregon-net-vpce-dynamodb"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_endpoint" "oregon-net-vpce-s3_S3" {
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_id            = aws_vpc.oregon-net-vpc.id
  policy            = "{\"Statement\":[{\"Action\":\"*\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"*\"}],\"Version\":\"2008-10-17\"}"
  route_table_ids   = [aws_route_table.oregon-net-rt-private-b.id, aws_route_table.oregon-net-rt-private-a.id, aws_route_table.oregon-net-rt-private-c.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    Name           = "oregon-net-vpce-s3"
    Project        = "oregon-net"
    DifName        = "oregon-net-vpce-s3"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_vpc_peering_connection" "pcx-0659fe288fc855311" {
  peer_vpc_id = aws_vpc.oregon-asg-vpc2.id
  vpc_id      = aws_vpc.oregon-net-vpc.id
  auto_accept = true
  accepter {
    allow_remote_vpc_dns_resolution = false
  }
  requester {
    allow_remote_vpc_dns_resolution = false
  }
  tags = {
    Name           = "oregon-asg-pcx"
    Project        = "oregon-asg"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-private-a" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.20.10.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net-private-a"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-private-b" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.20.11.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net-private-b"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-private-c" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.20.12.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net-private-c"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-a" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.20.0.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net-public-a"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-b" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.20.1.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net-public-b"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "oregon-net-public-c" {
  vpc_id                              = aws_vpc.oregon-net-vpc.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.20.2.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "oregon-net-public-c"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "oregon-net-igw" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-igw"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_egress_only_internet_gateway" "eigw-083dc9b065af87635" {
  id     = "eigw-083dc9b065af87635"
  vpc_id = aws_vpc.oregon-asg-vpc2.id
  tags = {
    Name           = "oregon-asg-eoigw"
    Project        = "oregon-asg"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_oregon-net-rt-public_to_pcx-0659fe288fc855311_10_20_0_0_16" {
  route_table_id            = aws_route_table.oregon-net-rt-public.id
  vpc_peering_connection_id = aws_vpc_peering_connection.pcx-0659fe288fc855311.id
  destination_cidr_block    = "10.20.0.0/16"
}

resource "aws_route_table" "oregon-net-rt-private-a" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-rt-private-a"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-b" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-rt-private-b"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-private-c" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-rt-private-c"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "oregon-net-rt-public" {
  vpc_id = aws_vpc.oregon-net-vpc.id
  tags = {
    Name           = "oregon-net-rt-public"
    Project        = "oregon-net"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_private_a_oregon_net_rt_private_a" {
  route_table_id = aws_route_table.oregon-net-rt-private-a.id
  subnet_id      = aws_subnet.oregon-net-private-a.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_private_b_oregon_net_rt_private_b" {
  route_table_id = aws_route_table.oregon-net-rt-private-b.id
  subnet_id      = aws_subnet.oregon-net-private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_private_c_oregon_net_rt_private_c" {
  route_table_id = aws_route_table.oregon-net-rt-private-c.id
  subnet_id      = aws_subnet.oregon-net-private-c.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_a_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_b_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-b.id
}

resource "aws_route_table_association" "aws_route_table_association_oregon_net_public_c_oregon_net_rt_public" {
  route_table_id = aws_route_table.oregon-net-rt-public.id
  subnet_id      = aws_subnet.oregon-net-public-c.id
}

resource "aws_network_acl" "oregon-asg-nacl" {
  vpc_id     = aws_vpc.oregon-net-vpc.id
  subnet_ids = [aws_subnet.oregon-net-public-a.id, aws_subnet.oregon-net-public-b.id, aws_subnet.oregon-net-public-c.id]
  tags = {
    Name           = "oregon-asg-nacl"
    Project        = "oregon-asg"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_network_acl_rule" "in_acl-09b3a9f00f5142610_100_ingress_0_0_0_0_0_tcp_port_443" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 443
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 100
  to_port        = 443
}

resource "aws_network_acl_rule" "in_acl-09b3a9f00f5142610_110_ingress_0_0_0_0_0_tcp_ports_1024_65535" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 1024
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 110
  to_port        = 65535
}

resource "aws_network_acl_rule" "in_infra_return_tcp_oregon-asg-nacl" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 32768
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 1001
  to_port        = 61000
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "in_infra_return_udp_oregon-asg-nacl" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = false
  from_port      = 32768
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 1002
  to_port        = 61000
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_acl-09b3a9f00f5142610_100_egress_0_0_0_0_0_tcp_all_ports" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  rule_action    = "allow"
  rule_number    = 100
}

resource "aws_network_acl_rule" "out_infra_oregon-asg-nacl_port_123_udp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 123
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 23233
  to_port        = 123
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_infra_oregon-asg-nacl_port_443_tcp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 443
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 28986
  to_port        = 443
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_infra_oregon-asg-nacl_port_53_tcp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 53
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 29875
  to_port        = 53
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_acl_rule" "out_infra_oregon-asg-nacl_port_53_udp" {
  network_acl_id = aws_network_acl.oregon-asg-nacl.id
  cidr_block     = "0.0.0.0/0"
  egress         = true
  from_port      = 53
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 15340
  to_port        = 53
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "oregon-asg-nodes" {
  name        = "oregon-asg-nodes"
  vpc_id      = aws_vpc.oregon-net-vpc.id
  description = "import lab -- nodes launched by the auto scaling group"
  lifecycle {
    ignore_changes = [revoke_rules_on_delete]
  }
  tags = {
    Name           = "oregon-asg-nodes"
    Project        = "oregon-asg"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_oregon_asg_nodes_egress_all_protocols" {
  security_group_id = aws_security_group.oregon-asg-nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_oregon_asg_nodes_ingress_tcp_443" {
  security_group_id = aws_security_group.oregon-asg-nodes.id
  cidr_blocks       = ["10.20.0.0/16"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  type              = "ingress"
}




### CATEGORY: COMPUTE ###

resource "aws_launch_template" "lt-0c672bbb12a42eab9" {
  image_id        = "ami-08a26983500a08011"
  key_name        = "oregon-asg-key"
  name            = "oregon-asg-lt"
  default_version = 1
  instance_type   = "t3.micro"
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
# --- END STRUCT8 VARIABLES ---


EOFUData
)
  vpc_security_group_ids = [aws_security_group.oregon-asg-nodes.id]
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      iops                  = 0
      throughput            = 0
      volume_size           = 8
      volume_type           = "gp3"
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
  monitoring {
    enabled = false
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Project        = "oregon-asg"
    Name           = "oregon-asg-group"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "oregon-asg-lt"
    Project        = "oregon-asg"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "oregon-asg-group" {
  name                    = "oregon-asg-group"
  default_instance_warmup = 0
  desired_capacity        = 0
  health_check_type       = "EC2"
  max_instance_lifetime   = 0
  max_size                = 2
  min_size                = 0
  vpc_zone_identifier     = [aws_subnet.oregon-net-private-a.id, aws_subnet.oregon-net-private-b.id, aws_subnet.oregon-net-private-c.id]
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }
  capacity_reservation_specification {
    capacity_reservation_preference = "default"
  }
  launch_template {
    version = aws_launch_template.lt-0c672bbb12a42eab9.latest_version
    id      = aws_launch_template.lt-0c672bbb12a42eab9.id
  }
  tag {
    key                 = "Project"
    propagate_at_launch = true
    value               = "oregon-asg"
  }
  tag {
    key                 = "Tier"
    propagate_at_launch = false
    value               = "lab"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "oregon-asg-group"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "Import-loop3"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "aws_vpc_flowlogs_oregon-asg" {
  name              = "/aws/vpc/flowlogs/oregon-asg"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  tags = {
    Name           = "aws_vpc_flowlogs_oregon-asg"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "TargetTracking-oregon-asg-group-AlarmHigh-e7c4c194-70b2-42d9-97e1-6be2ecfb75b1" {
  alarm_name          = "TargetTracking-oregon-asg-group-AlarmHigh-e7c4c194-70b2-42d9-97e1-6be2ecfb75b1"
  metric_name         = "CPUUtilization"
  alarm_actions       = ["arn:aws:autoscaling:us-west-2:952133486861:scalingPolicy:e75439c3-3434-4882-82ee-10d9b2f53968:autoScalingGroupName/oregon-asg-group:policyName/oregon-asg-cpu60"]
  alarm_description   = "DO NOT EDIT OR DELETE. For TargetTrackingScaling policy arn:aws:autoscaling:us-west-2:952133486861:scalingPolicy:e75439c3-3434-4882-82ee-10d9b2f53968:autoScalingGroupName/oregon-asg-group:policyName/oregon-asg-cpu60."
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 0
  evaluation_interval = 0
  evaluation_periods  = 3
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 60
  dimensions = {
    AutoScalingGroupName = "oregon-asg-group"
  }
  tags = {
    Name           = "TargetTracking-oregon-asg-group-AlarmHigh-e7c4c194-70b2-42d9-97e1-6be2ecfb75b1"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "TargetTracking-oregon-asg-group-AlarmLow-fd52bd60-2ef8-4aee-b3c2-b26fe987d593" {
  alarm_name          = "TargetTracking-oregon-asg-group-AlarmLow-fd52bd60-2ef8-4aee-b3c2-b26fe987d593"
  metric_name         = "CPUUtilization"
  alarm_actions       = ["arn:aws:autoscaling:us-west-2:952133486861:scalingPolicy:e75439c3-3434-4882-82ee-10d9b2f53968:autoScalingGroupName/oregon-asg-group:policyName/oregon-asg-cpu60"]
  alarm_description   = "DO NOT EDIT OR DELETE. For TargetTrackingScaling policy arn:aws:autoscaling:us-west-2:952133486861:scalingPolicy:e75439c3-3434-4882-82ee-10d9b2f53968:autoScalingGroupName/oregon-asg-group:policyName/oregon-asg-cpu60."
  comparison_operator = "LessThanThreshold"
  datapoints_to_alarm = 0
  evaluation_interval = 0
  evaluation_periods  = 15
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 54
  dimensions = {
    AutoScalingGroupName = "oregon-asg-group"
  }
  tags = {
    Name           = "TargetTracking-oregon-asg-group-AlarmLow-fd52bd60-2ef8-4aee-b3c2-b26fe987d593"
    State          = "Import-loop3"
    Struct8Creator = "Contato Struct"
  }
}


