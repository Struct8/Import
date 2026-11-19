data "archive_file" "archive_struct8-templates_analyticsPage" {
  output_path = "${path.module}/struct8-templates_analyticsPage.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/lambda/analytics"
  type        = "zip"
}

resource "aws_lambda_function" "analyticsPage" {
  function_name                  = "analyticsPage"
  architectures                  = ["arm64"]
  description                    = "Analytics page: runs the CDN log queries in Athena and returns HTML."
  filename                       = data.archive_file.archive_struct8-templates_analyticsPage.output_path
  handler                        = "index.handler"
  memory_size                    = 1900
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.analyticsPage_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-templates_analyticsPage.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
      ATHENA_WORKGROUP               = aws_athena_workgroup.cdnAnalytics.name
      GLUE_DATABASE                  = aws_glue_catalog_database.cdn_analytics.name
      GLUE_TABLE                     = aws_glue_catalog_table.cdn_log.name
      NAME                           = "analyticsPage"
      REGION                         = data.aws_region.current.region
      ACCOUNT                        = data.aws_caller_identity.current.account_id
      AWS_LAMBDA_FUNCTION_URL_NAME_0 = "analyticsUrl"
      AWS_S3_BUCKET_NAME_0           = "cdnlogbucket-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      AWS_ATHENA_WORKGROUP_NAME_0    = "cdnAnalytics"
      AWS_GLUE_CATALOG_TABLE_NAME_0  = "cdn_log"
      AWS_DYNAMODB_TABLE_NAME_0      = "cspTable"
    }
  }
  tags = {
    Name           = "analyticsPage"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_analyticsPage_st_wp-analytics_attach]
}

data "archive_file" "archive_struct8-templates_cspReceiver" {
  output_path = "${path.module}/struct8-templates_cspReceiver.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/wordpress-professional/v1/lambda/csp-receiver"
  type        = "zip"
}

resource "aws_lambda_function" "cspReceiver" {
  function_name                  = "cspReceiver"
  architectures                  = ["arm64"]
  description                    = "Receives CSP violation reports from browsers and counts them in cspTable."
  filename                       = data.archive_file.archive_struct8-templates_cspReceiver.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.cspReceiver_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_struct8-templates_cspReceiver.output_base64sha256
  timeout                        = 10
  environment {
    variables = {
      NAME                           = "cspReceiver"
      REGION                         = data.aws_region.current.region
      ACCOUNT                        = data.aws_caller_identity.current.account_id
      AWS_LAMBDA_FUNCTION_URL_NAME_0 = "cspReceiverUrl"
      AWS_DYNAMODB_TABLE_NAME_0      = "cspTable"
      SITE_HOST                      = "wp.cloudman.pro"
    }
  }
  tags = {
    Name           = "cspReceiver"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_cspReceiver_st_wp-analytics_attach]
}

resource "aws_lambda_function_url" "analyticsUrl" {
  function_name      = aws_lambda_function.analyticsPage.function_name
  authorization_type = "AWS_IAM"
}

resource "aws_lambda_function_url" "cspReceiverUrl" {
  function_name      = aws_lambda_function.cspReceiver.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver" {
  function_name          = aws_lambda_function.cspReceiver.function_name
  principal              = "*"
  action                 = "lambda:InvokeFunctionUrl"
  function_url_auth_type = "NONE"
  statement_id_prefix    = "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver"
  depends_on             = [aws_lambda_function_url.cspReceiverUrl]
}

resource "aws_lambda_permission" "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver_invoke" {
  function_name            = aws_lambda_function.cspReceiver.function_name
  principal                = "*"
  action                   = "lambda:InvokeFunction"
  invoked_via_function_url = true
  statement_id_prefix      = "perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver_invoke"
  depends_on               = [aws_lambda_function_url.cspReceiverUrl, aws_lambda_permission.perm_aws_lambda_function_url_cspReceiverUrl_to_cspReceiver]
}

resource "aws_appautoscaling_policy" "sc_policy_Read_cspTable" {
  name               = "DynamoDBReadCapacityUtilization:sc_target_Read_cspTable"
  resource_id        = aws_appautoscaling_target.sc_target_Read_cspTable.resource_id
  policy_type        = "TargetTrackingScaling"
  scalable_dimension = aws_appautoscaling_target.sc_target_Read_cspTable.scalable_dimension
  service_namespace  = aws_appautoscaling_target.sc_target_Read_cspTable.service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
  }
}

resource "aws_appautoscaling_target" "sc_target_Read_cspTable" {
  resource_id        = "table/${aws_dynamodb_table.cspTable.name}"
  max_capacity       = 20
  min_capacity       = 5
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
  tags = {
    Name           = "sc_target_Read_cspTable"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}
