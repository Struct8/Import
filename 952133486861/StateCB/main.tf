terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/StateCB/main.tfstate"
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

### CATEGORY: INTEGRATION ###

resource "aws_sns_topic" "Topic1" {
  name                        = "Topic1.fifo"
  content_based_deduplication = false
  delivery_policy             = "{\"a\":\"b\"}"
  fifo_throughput_scope       = "Topic"
  fifo_topic                  = true
  tags = {
    Name           = "Topic1"
    State          = "StateCB"
    Struct8Creator = "Contato Struct"
  }
}


