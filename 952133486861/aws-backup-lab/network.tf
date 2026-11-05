resource "aws_vpc" "aws-backup-lab" {
  cidr_block           = "10.21.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "aws-backup-lab"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "pubA1" {
  vpc_id                  = aws_vpc.aws-backup-lab.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.21.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name           = "pubA1"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-backup-lab" {
  vpc_id = aws_vpc.aws-backup-lab.id
  tags = {
    Name           = "igw-backup-lab"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-public-backup-lab_to_igw-backup-lab_ipv4" {
  gateway_id             = aws_internet_gateway.igw-backup-lab.id
  route_table_id         = aws_route_table.rt-public-backup-lab.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-public-backup-lab" {
  vpc_id = aws_vpc.aws-backup-lab.id
  tags = {
    Name           = "rt-public-backup-lab"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_pubA1_rt_public_backup_lab" {
  route_table_id = aws_route_table.rt-public-backup-lab.id
  subnet_id      = aws_subnet.pubA1.id
}

resource "aws_security_group" "ecs_task_definition_efs-writer_group" {
  name                   = "ecs_task_definition_efs-writer_group"
  vpc_id                 = aws_vpc.aws-backup-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "ecs_task_definition_efs-writer_group"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "efs_file_system_lab-data_group" {
  name                   = "efs_file_system_lab-data_group"
  vpc_id                 = aws_vpc.aws-backup-lab.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "efs_file_system_lab-data_group"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_ecs_task_definition_efs_writer_group_egress_all_protocols" {
  security_group_id = aws_security_group.ecs_task_definition_efs-writer_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_ecs_task_definition_efs_writer_group_to_efs_file_system_lab_data_group_tcp_2049" {
  security_group_id        = aws_security_group.efs_file_system_lab-data_group.id
  source_security_group_id = aws_security_group.ecs_task_definition_efs-writer_group.id
  description              = "Allow from ecs_task_definition_efs-writer_group (tcp:2049-2049)"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_efs_file_system_lab_data_group_egress_all_protocols" {
  security_group_id = aws_security_group.efs_file_system_lab-data_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}
