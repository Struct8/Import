terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/StateFul-mon/main.tfstate"
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

data "aws_vpc" "vpc-grafana-lgtm-mon" {
  filter {
    name   = "tag:Name"
    values = ["vpc-grafana-lgtm-mon"]
  }
}




### CATEGORY: NETWORK ###

resource "aws_subnet" "snet-data-1a-mon" {
  vpc_id                  = data.aws_vpc.vpc-grafana-lgtm-mon.id
  availability_zone       = "us-west-2a"
  cidr_block              = "10.4.4.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "snet-data-1a-mon"
    State          = "StateFul-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "snet-data-1b-mon" {
  vpc_id                  = data.aws_vpc.vpc-grafana-lgtm-mon.id
  availability_zone       = "us-west-2b"
  cidr_block              = "10.4.5.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name           = "snet-data-1b-mon"
    State          = "StateFul-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "efs_file_system_efs-grafana-lgtm-mon_group" {
  name                   = "efs_file_system_efs-grafana-lgtm-mon_group"
  vpc_id                 = data.aws_vpc.vpc-grafana-lgtm-mon.id
  revoke_rules_on_delete = false
  tags = {
    Name           = "efs_file_system_efs-grafana-lgtm-mon_group"
    State          = "StateFul-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_efs_file_system_efs_grafana_lgtm_mon_group_egress_all_protocols" {
  security_group_id = aws_security_group.efs_file_system_efs-grafana-lgtm-mon_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "lgtm-grafana-config-mon" {
  bucket              = "lgtm-grafana-config-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "lgtm-grafana-config-mon"
    State          = "StateFul-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "lgtm-loki-chunks-mon" {
  bucket              = "lgtm-loki-chunks-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "lgtm-loki-chunks-mon"
    State          = "StateFul-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "lgtm-tempo-blocks-mon" {
  bucket              = "lgtm-tempo-blocks-mon-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "lgtm-tempo-blocks-mon"
    State          = "StateFul-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "lgtm-grafana-config-mon_controls" {
  bucket = aws_s3_bucket.lgtm-grafana-config-mon.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "lgtm-loki-chunks-mon_controls" {
  bucket = aws_s3_bucket.lgtm-loki-chunks-mon.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "lgtm-tempo-blocks-mon_controls" {
  bucket = aws_s3_bucket.lgtm-tempo-blocks-mon.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "lgtm-grafana-config-mon_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.lgtm-grafana-config-mon.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "lgtm-loki-chunks-mon_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.lgtm-loki-chunks-mon.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "lgtm-tempo-blocks-mon_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.lgtm-tempo-blocks-mon.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lgtm-grafana-config-mon_configuration" {
  bucket = aws_s3_bucket.lgtm-grafana-config-mon.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lgtm-loki-chunks-mon_configuration" {
  bucket = aws_s3_bucket.lgtm-loki-chunks-mon.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lgtm-tempo-blocks-mon_configuration" {
  bucket = aws_s3_bucket.lgtm-tempo-blocks-mon.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "lgtm-grafana-config-mon_versioning" {
  bucket = aws_s3_bucket.lgtm-grafana-config-mon.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "lgtm-loki-chunks-mon_versioning" {
  bucket = aws_s3_bucket.lgtm-loki-chunks-mon.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "lgtm-tempo-blocks-mon_versioning" {
  bucket = aws_s3_bucket.lgtm-tempo-blocks-mon.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_efs_file_system" "efs-grafana-lgtm-mon" {
  encrypted       = true
  throughput_mode = "elastic"
  tags = {
    Name           = "efs-grafana-lgtm-mon"
    State          = "StateFul-mon"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_efs_mount_target" "mt_efs-grafana-lgtm-mon_snet-data-1a-mon" {
  file_system_id  = aws_efs_file_system.efs-grafana-lgtm-mon.id
  subnet_id       = aws_subnet.snet-data-1a-mon.id
  security_groups = [aws_security_group.efs_file_system_efs-grafana-lgtm-mon_group.id]
}

resource "aws_efs_mount_target" "mt_efs-grafana-lgtm-mon_snet-data-1b-mon" {
  file_system_id  = aws_efs_file_system.efs-grafana-lgtm-mon.id
  subnet_id       = aws_subnet.snet-data-1b-mon.id
  security_groups = [aws_security_group.efs_file_system_efs-grafana-lgtm-mon_group.id]
}


