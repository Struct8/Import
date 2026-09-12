terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/Import/main.tfstate"
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

resource "aws_iam_role" "StreamConsumer1_role" {
  name                  = "StreamConsumer1_role"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "StreamConsumer1_role"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_kinesis_streaming_destination" "Ledger1_to_LedgerKinesisStream1" {
  table_name = aws_dynamodb_table.Ledger1.name
  stream_arn = aws_kinesis_stream.LedgerKinesisStream1.arn
}

resource "aws_dynamodb_table" "Events-OnDemand1" {
  name                        = "Events-OnDemand1"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "EventId"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "EventId"
    type = "S"
  }
  point_in_time_recovery {
    enabled = false
  }
  tags = {
    Name           = "Events-OnDemand1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    enabled = false
  }
}

resource "aws_dynamodb_table" "Ledger1" {
  name                        = "Ledger1"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "AccountId"
  range_key                   = "TxnId"
  stream_enabled              = true
  stream_view_type            = "NEW_AND_OLD_IMAGES"
  table_class                 = "STANDARD"
  attribute {
    name = "AccountId"
    type = "S"
  }
  attribute {
    name = "TxnId"
    type = "S"
  }
  point_in_time_recovery {
    enabled = false
  }
  tags = {
    Name           = "Ledger1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    enabled = false
  }
}

resource "aws_dynamodb_table" "Metrics-Autoscaling1" {
  name                        = "Metrics-Autoscaling1"
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "MetricId"
  read_capacity               = 1
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 1
  attribute {
    name = "MetricId"
    type = "S"
  }
  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
  point_in_time_recovery {
    enabled = false
  }
  tags = {
    Name           = "Metrics-Autoscaling1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    enabled = false
  }
}

resource "aws_dynamodb_table" "Orders1" {
  name                        = "Orders1"
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "OrderId"
  range_key                   = "CreatedAt"
  read_capacity               = 1
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 1
  attribute {
    name = "CreatedAt"
    type = "S"
  }
  attribute {
    name = "OrderId"
    type = "S"
  }
  point_in_time_recovery {
    enabled = false
  }
  tags = {
    Name           = "Orders1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    enabled = false
  }
}

resource "aws_dynamodb_table" "Sessions1" {
  name                        = "Sessions1"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "SessionId"
  stream_enabled              = false
  table_class                 = "STANDARD_INFREQUENT_ACCESS"
  attribute {
    name = "SessionId"
    type = "S"
  }
  point_in_time_recovery {
    enabled                 = true
    recovery_period_in_days = 35
  }
  tags = {
    Name           = "Sessions1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "Users1" {
  name                        = "Users1"
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "UserId"
  range_key                   = "ProfileType"
  read_capacity               = 1
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 1
  attribute {
    name = "Country"
    type = "S"
  }
  attribute {
    name = "Email"
    type = "S"
  }
  attribute {
    name = "Fingerprint"
    type = "B"
  }
  attribute {
    name = "ProfileType"
    type = "S"
  }
  attribute {
    name = "Score"
    type = "N"
  }
  attribute {
    name = "UserId"
    type = "S"
  }
  global_secondary_index {
    name            = "ByCountry"
    hash_key        = "Country"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }
  global_secondary_index {
    name            = "ByEmailAutoscale"
    hash_key        = "Email"
    projection_type = "KEYS_ONLY"
    read_capacity   = 1
    write_capacity  = 1
  }
  global_secondary_index {
    name               = "ByProfileInclude"
    hash_key           = "ProfileType"
    non_key_attributes = ["Country", "Email"]
    projection_type    = "INCLUDE"
    read_capacity      = 1
    write_capacity     = 1
  }
  local_secondary_index {
    name            = "ByEmail"
    projection_type = "KEYS_ONLY"
    range_key       = "Email"
  }
  local_secondary_index {
    name               = "ByFingerprintInclude"
    non_key_attributes = ["Email"]
    projection_type    = "INCLUDE"
    range_key          = "Fingerprint"
  }
  local_secondary_index {
    name            = "ByScoreAll"
    projection_type = "ALL"
    range_key       = "Score"
  }
  point_in_time_recovery {
    enabled = false
  }
  tags = {
    Name           = "Users1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    enabled = false
  }
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_event_source_mapping" "LedgerStreamMapping1" {
  function_name                      = aws_lambda_function.StreamConsumer1.arn
  batch_size                         = 100
  bisect_batch_on_function_error     = false
  event_source_arn                   = aws_dynamodb_table.Ledger1.stream_arn
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 5
  maximum_record_age_in_seconds      = -1
  maximum_retry_attempts             = -1
  parallelization_factor             = 1
  starting_position                  = "LATEST"
  tags = {
    Name           = "LedgerStreamMapping1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lambda_function" "StreamConsumer1" {
  function_name                  = "StreamConsumer1"
  architectures                  = ["arm64"]
  filename                       = "imported_lambda_placeholder.zip"
  handler                        = "index.handler"
  memory_size                    = 128
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.StreamConsumer1_role.arn
  runtime                        = "nodejs22.x"
  timeout                        = 30
  environment {
    variables = {
    ACCOUNT = "952133486861"
    NAME    = "StreamConsumer1"
    REGION  = "us-west-2"
  }
  }
  ephemeral_storage {
    size = 512
  }
  lifecycle {
    ignore_changes = [filename, source_code_hash, publish]
  }
  logging_config {
    log_format = "Text"
  }
  tags = {
    Name           = "StreamConsumer1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_policy" "sc_policy_Read_ByEmailAutoscale_Users1" {
  name               = "DynamoDBReadCapacityUtilization:sc_target_Read_ByEmailAutoscale_Users1"
  resource_id        = aws_appautoscaling_target.sc_target_Read_ByEmailAutoscale_Users1.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Read_ByEmailAutoscale_Users1.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Read_ByEmailAutoscale_Users1.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "sc_policy_Read_Metrics-Autoscaling1" {
  name               = "DynamoDBReadCapacityUtilization:sc_target_Read_Metrics-Autoscaling1"
  resource_id        = aws_appautoscaling_target.sc_target_Read_Metrics-Autoscaling1.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Read_Metrics-Autoscaling1.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Read_Metrics-Autoscaling1.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "sc_policy_Write_ByEmailAutoscale_Users1" {
  name               = "DynamoDBWriteCapacityUtilization:sc_target_Write_ByEmailAutoscale_Users1"
  resource_id        = aws_appautoscaling_target.sc_target_Write_ByEmailAutoscale_Users1.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Write_ByEmailAutoscale_Users1.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Write_ByEmailAutoscale_Users1.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "sc_policy_Write_Metrics-Autoscaling1" {
  name               = "DynamoDBWriteCapacityUtilization:sc_target_Write_Metrics-Autoscaling1"
  resource_id        = aws_appautoscaling_target.sc_target_Write_Metrics-Autoscaling1.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Write_Metrics-Autoscaling1.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Write_Metrics-Autoscaling1.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "sc_target_Read_ByEmailAutoscale_Users1" {
  resource_id        = "table/${aws_dynamodb_table.Users1.name}/index/ByEmailAutoscale"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Read_ByEmailAutoscale_Users1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "sc_target_Read_Metrics-Autoscaling1" {
  resource_id        = "table/${aws_dynamodb_table.Metrics-Autoscaling1.name}"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Read_Metrics-Autoscaling1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "sc_target_Write_ByEmailAutoscale_Users1" {
  resource_id        = "table/${aws_dynamodb_table.Users1.name}/index/ByEmailAutoscale"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Write_ByEmailAutoscale_Users1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "sc_target_Write_Metrics-Autoscaling1" {
  resource_id        = "table/${aws_dynamodb_table.Metrics-Autoscaling1.name}"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Write_Metrics-Autoscaling1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: INTEGRATION ###

resource "aws_kinesis_stream" "LedgerKinesisStream1" {
  name        = "LedgerKinesisStream1"
  shard_count = 1
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
  tags = {
    Name           = "LedgerKinesisStream1"
    State          = "dynamodb-tour1"
    Struct8Creator = "Contato Struct"
  }
}


