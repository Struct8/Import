data "archive_file" "archive_struct8-hub_cross-caller" {
  output_path = "${path.module}/struct8-hub_cross-caller.zip"
  source_dir  = "${path.module}/.external_modules/struct8-hub/prebuilt"
  type        = "zip"
}

resource "aws_lambda_function" "cross-caller" {
  function_name                  = "cross-caller"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_struct8-hub_cross-caller.output_path
  handler                        = "index.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.cross-caller_role.arn
  runtime                        = "nodejs22.x"
  source_code_hash               = data.archive_file.archive_struct8-hub_cross-caller.output_base64sha256
  timeout                        = 60
  environment {
    variables = {
      NAME                                      = "cross-caller"
      REGION                                    = data.aws_region.current.region
      ACCOUNT                                   = data.aws_caller_identity.current.account_id
      AWS_XRAY_GROUP_NAME_0                     = "cross-traces"
      GOOGLE_WORKLOAD_PROVIDER                  = "projects/233610591017/locations/global/workloadIdentityPools/cross-link/providers/aws-workload"
      GOOGLE_SERVICE_ACCOUNT                    = "cross-link@deft-landing-343414.iam.gserviceaccount.com"
      GOOGLE_CLOUDFUNCTIONS2_FUNCTION_URL_0     = "https://us-central1-deft-landing-343414.cloudfunctions.net/cross-gateway"
      GOOGLE_CLOUDFUNCTIONS2_FUNCTION_ACCOUNT_0 = "deft-landing-343414"
      GOOGLE_PUBSUB_TOPIC_NAME_0                = "cross-events"
      GOOGLE_PUBSUB_TOPIC_ACCOUNT_0             = "deft-landing-343414"
      GOOGLE_STORAGE_BUCKET_NAME_0              = "deft-landing-343414-cross-data"
      GOOGLE_STORAGE_BUCKET_ACCOUNT_0           = "deft-landing-343414"
      GOOGLE_SECRET_MANAGER_SECRET_NAME_0       = "cross-secret"
      GOOGLE_SECRET_MANAGER_SECRET_ACCOUNT_0    = "deft-landing-343414"
    }
  }
  tags = {
    Name           = "cross-caller"
    State          = "stateHubCrossAws"
    Struct8Creator = "Contato Struct"
  }
  tracing_config {
    mode = "Active"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_cross-caller_st_stateHubCrossAws_attach]
}
