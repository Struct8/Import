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
    key     = "952133486861/dynamodb-tour/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "ca-central-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

data "aws_iam_policy_document" "lambda_function_StreamConsumer_st_dynamodb-tour_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.LogGroup.arn}:*"]
  }
  statement {
    sid       = "AllowEventSourceRead"
    effect    = "Allow"
    actions   = ["dynamodb:DescribeStream", "dynamodb:GetRecords", "dynamodb:GetShardIterator"]
    resources = [aws_dynamodb_table.Ledger.stream_arn]
  }
}

resource "aws_iam_policy" "lambda_function_StreamConsumer_st_dynamodb-tour" {
  name        = "lambda_function_StreamConsumer_st_dynamodb-tour"
  description = "Access Policy for StreamConsumer"
  policy      = data.aws_iam_policy_document.lambda_function_StreamConsumer_st_dynamodb-tour_doc.json
}

resource "aws_iam_role" "StreamConsumer_role" {
  name = "StreamConsumer_role"
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
    Name           = "StreamConsumer_role"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_function_StreamConsumer_st_dynamodb-tour_attach" {
  policy_arn = aws_iam_policy.lambda_function_StreamConsumer_st_dynamodb-tour.arn
  role       = aws_iam_role.StreamConsumer_role.name
}




### CATEGORY: DATABASE ###

resource "aws_dynamodb_kinesis_streaming_destination" "KinesisDestination" {
  table_name = aws_dynamodb_table.Ledger.name
  stream_arn = aws_kinesis_stream.LedgerKinesisStream.arn
}

resource "aws_dynamodb_table" "EventsOnDemand" {
  name                        = "EventsOnDemand"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "EventId"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "EventId"
    type = "S"
  }
  tags = {
    Name           = "EventsOnDemand"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table" "Ledger" {
  name                        = "Ledger"
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
  tags = {
    Name           = "Ledger"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table" "MetricsAutoscaling" {
  name                        = "MetricsAutoscaling"
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
  tags = {
    Name           = "MetricsAutoscaling"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table" "Orders" {
  name                        = "Orders"
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "OrderId"
  range_key                   = "CreatedAt"
  read_capacity               = 1
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 1
  attribute {
    name = "OrderId"
    type = "S"
  }
  attribute {
    name = "CreatedAt"
    type = "S"
  }
  tags = {
    Name           = "Orders"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table" "RestoredLatest" {
  name                        = "RestoredLatest"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "Id"
  restore_to_latest_time      = true
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "Id"
    type = "S"
  }
  tags = {
    Name           = "RestoredLatest"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table" "RestoredPointInTime" {
  name                        = "RestoredPointInTime"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "Id"
  restore_date_time           = "2026-01-01T00:00:00Z"
  stream_enabled              = false
  table_class                 = "STANDARD"
  attribute {
    name = "Id"
    type = "S"
  }
  tags = {
    Name           = "RestoredPointInTime"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table" "Sessions" {
  name                        = "Sessions"
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
    enabled = true
  }
  tags = {
    Name           = "Sessions"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
  ttl {
    attribute_name = "ExpiresAt"
    enabled        = true
  }
}

resource "aws_dynamodb_table" "Users" {
  name                        = "Users"
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "UserId"
  range_key                   = "ProfileType"
  read_capacity               = 1
  stream_enabled              = false
  table_class                 = "STANDARD"
  write_capacity              = 1
  attribute {
    name = "UserId"
    type = "S"
  }
  attribute {
    name = "ProfileType"
    type = "S"
  }
  attribute {
    name = "Email"
    type = "S"
  }
  attribute {
    name = "Country"
    type = "S"
  }
  attribute {
    name = "Score"
    type = "N"
  }
  attribute {
    name = "Fingerprint"
    type = "B"
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
    non_key_attributes = ["Email", "Country"]
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
    name            = "ByScoreAll"
    projection_type = "ALL"
    range_key       = "Score"
  }
  local_secondary_index {
    name               = "ByFingerprintInclude"
    non_key_attributes = ["Email"]
    projection_type    = "INCLUDE"
    range_key          = "Fingerprint"
  }
  tags = {
    Name           = "Users"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_dynamodb_table_item" "AdminUser" {
  table_name = aws_dynamodb_table.Users.name
  hash_key   = aws_dynamodb_table.Users.hash_key
  item = <<EOF
{
  "UserId": {"S": "USR-7"},
  "ProfileType": {"S": "ADMIN"},
  "Email": {"S": "alice@example.com"},
  "Country": {"S": "BR"},
  "Score": {"N": "980"},
  "Tags": {"SS": ["vip", "beta"]}
}
  EOF
  range_key = aws_dynamodb_table.Users.range_key
}

resource "aws_dynamodb_table_item" "OrderPending" {
  table_name = aws_dynamodb_table.Orders.name
  hash_key   = aws_dynamodb_table.Orders.hash_key
  item = <<EOF
{
  "OrderId": {"S": "ORD-1002"},
  "CreatedAt": {"S": "2026-02-01T08:15:00Z"},
  "Total": {"N": "32.50"},
  "Status": {"S": "PENDING"}
}
  EOF
  range_key = aws_dynamodb_table.Orders.range_key
}

resource "aws_dynamodb_table_item" "OrderShipped" {
  table_name = aws_dynamodb_table.Orders.name
  hash_key   = aws_dynamodb_table.Orders.hash_key
  item = <<EOF
{
  "OrderId": {"S": "ORD-1001"},
  "CreatedAt": {"S": "2026-01-15T10:30:00Z"},
  "Total": {"N": "149.90"},
  "Status": {"S": "SHIPPED"}
}
  EOF
  range_key = aws_dynamodb_table.Orders.range_key
}

resource "aws_dynamodb_table_item" "SignupEvent" {
  table_name = aws_dynamodb_table.EventsOnDemand.name
  hash_key   = aws_dynamodb_table.EventsOnDemand.hash_key
  item = <<EOF
{
  "EventId": {"S": "EVT-abc123"},
  "Type": {"S": "user.signup"},
  "Payload": {"M": {"plan": {"S": "free"}, "referred": {"BOOL": false}}}
}
  EOF
  range_key = aws_dynamodb_table.EventsOnDemand.range_key
}




### CATEGORY: COMPUTE ###

resource "aws_lambda_event_source_mapping" "LedgerStreamMapping" {
  function_name                      = aws_lambda_function.StreamConsumer.arn
  batch_size                         = 100
  bisect_batch_on_function_error     = false
  event_source_arn                   = aws_dynamodb_table.Ledger.stream_arn
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 5
  maximum_record_age_in_seconds      = -1
  maximum_retry_attempts             = -1
  starting_position                  = "LATEST"
  tags = {
    Name           = "LedgerStreamMapping"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

data "archive_file" "archive_struct8-hub_StreamConsumer" {
  output_path = "${path.module}/struct8-hub_StreamConsumer.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "StreamConsumer" {
  function_name                  = "StreamConsumer"
  architectures                  = ["arm64"]
  description                    = "Stream consumer running the Struct8 hub (code from Struct8/struct8-hub prebuilt). It reads the Ledger stream via the Event Source Mapping and reports each hop."
  filename                       = data.archive_file.archive_struct8-hub_StreamConsumer.output_path
  handler                        = "index.handler"
  memory_size                    = 128
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.StreamConsumer_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_StreamConsumer.output_base64sha256
  timeout                        = 30
  environment {
    variables = {
    NAME    = "StreamConsumer"
    REGION  = data.aws_region.current.region
    ACCOUNT = data.aws_caller_identity.current.account_id
  }
  }
  tags = {
    Name           = "StreamConsumer"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_StreamConsumer_st_dynamodb-tour_attach]
}

resource "aws_appautoscaling_policy" "sc_policy_Read_ByEmailAutoscale_Users" {
  name               = "DynamoDBReadCapacityUtilization:sc_target_Read_ByEmailAutoscale_Users"
  resource_id        = aws_appautoscaling_target.sc_target_Read_ByEmailAutoscale_Users.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Read_ByEmailAutoscale_Users.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Read_ByEmailAutoscale_Users.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "sc_policy_Read_MetricsAutoscaling" {
  name               = "DynamoDBReadCapacityUtilization:sc_target_Read_MetricsAutoscaling"
  resource_id        = aws_appautoscaling_target.sc_target_Read_MetricsAutoscaling.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Read_MetricsAutoscaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Read_MetricsAutoscaling.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "sc_policy_Write_ByEmailAutoscale_Users" {
  name               = "DynamoDBWriteCapacityUtilization:sc_target_Write_ByEmailAutoscale_Users"
  resource_id        = aws_appautoscaling_target.sc_target_Write_ByEmailAutoscale_Users.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Write_ByEmailAutoscale_Users.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Write_ByEmailAutoscale_Users.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "sc_policy_Write_MetricsAutoscaling" {
  name               = "DynamoDBWriteCapacityUtilization:sc_target_Write_MetricsAutoscaling"
  resource_id        = aws_appautoscaling_target.sc_target_Write_MetricsAutoscaling.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Write_MetricsAutoscaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Write_MetricsAutoscaling.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "sc_target_Read_ByEmailAutoscale_Users" {
  resource_id        = "table/${aws_dynamodb_table.Users.name}/index/ByEmailAutoscale"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Read_ByEmailAutoscale_Users"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "sc_target_Read_MetricsAutoscaling" {
  resource_id        = "table/${aws_dynamodb_table.MetricsAutoscaling.name}"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Read_MetricsAutoscaling"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "sc_target_Write_ByEmailAutoscale_Users" {
  resource_id        = "table/${aws_dynamodb_table.Users.name}/index/ByEmailAutoscale"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Write_ByEmailAutoscale_Users"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_appautoscaling_target" "sc_target_Write_MetricsAutoscaling" {
  resource_id        = "table/${aws_dynamodb_table.MetricsAutoscaling.name}"
  max_capacity       = 10
  min_capacity       = 1
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Write_MetricsAutoscaling"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: INTEGRATION ###

resource "aws_kinesis_stream" "LedgerKinesisStream" {
  name        = "LedgerKinesisStream"
  shard_count = 1
  tags = {
    Name           = "LedgerKinesisStream"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: MONITORING ###

resource "aws_cloudwatch_log_group" "LogGroup" {
  name              = "/aws/lambda/StreamConsumer"
  log_group_class   = "STANDARD"
  retention_in_days = 1
  skip_destroy      = false
  tags = {
    Name           = "LogGroup"
    State          = "dynamodb-tour"
    Struct8Creator = "Contato Struct"
  }
}


