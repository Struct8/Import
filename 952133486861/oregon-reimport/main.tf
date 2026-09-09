terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/oregon-reimport/main.tfstate"
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

data "aws_vpc" "oregon-asg-vpc2" {
  filter {
    name   = "tag:Name"
    values = ["oregon-asg-vpc2"]
  }
}

data "aws_vpc" "oregon-net-vpc" {
  filter {
    name   = "tag:Name"
    values = ["oregon-net-vpc"]
  }
}

data "aws_route_table" "oregon-net-rt-public" {
  filter {
    name   = "tag:Name"
    values = ["oregon-net-rt-public"]
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc_peering_connection" "pcx-0659fe288fc855311" {
  peer_vpc_id = data.aws_vpc.oregon-asg-vpc2.id
  vpc_id      = data.aws_vpc.oregon-net-vpc.id
  accepter {
    allow_remote_vpc_dns_resolution = false
  }
  requester {
    allow_remote_vpc_dns_resolution = false
  }
  tags = {
    Name           = "oregon-asg-pcx"
    Project        = "oregon-asg"
    State          = "oregon-reimport"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_oregon-net-rt-public_to_pcx-0659fe288fc855311_10_30_0_0_16" {
  route_table_id            = data.aws_route_table.oregon-net-rt-public.id
  vpc_peering_connection_id = aws_vpc_peering_connection.pcx-0659fe288fc855311.id
  destination_cidr_block    = "10.30.0.0/16"
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
    State          = "oregon-reimport"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_cloudwatch_metric_alarm" "TargetTracking-oregon-asg-group-AlarmLow-fd52bd60-2ef8-4aee-b3c2-b26fe987d593" {
  alarm_name          = "TargetTracking-oregon-asg-group-AlarmLow-fd52bd60-2ef8-4aee-b3c2-b26fe987d593"
  metric_name         = "CPUUtilization"
  alarm_actions       = ["arn:aws:autoscaling:us-west-2:952133486861:scalingPolicy:e75439c3-3434-4882-82ee-10d9b2f53968:autoScalingGroupName/oregon-asg-group:policyName/oregon-asg-cpu60"]
  alarm_description   = "DO NOT EDIT OR DELETE. For TargetTrackingScaling policy arn:aws:autoscaling:us-west-2:952133486861:scalingPolicy:e75439c3-3434-4882-82ee-10d9b2f53968:autoScalingGroupName/oregon-asg-group:policyName/oregon-asg-cpu60."
  comparison_operator = "LessThanThreshold"
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
    State          = "oregon-reimport"
    Struct8Creator = "Contato Struct"
  }
}


