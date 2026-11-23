data "archive_file" "archive_Import_r2-lab-fn" {
  output_path = "${path.module}/Import_r2-lab-fn.zip"
  source_dir  = "${path.module}/.external_modules/Import/lab/r2-gateway/lambda"
  type        = "zip"
}

resource "aws_lambda_function" "r2-lab-fn" {
  function_name                  = "r2-lab-fn"
  architectures                  = ["arm64"]
  filename                       = data.archive_file.archive_Import_r2-lab-fn.output_path
  handler                        = "lab.handler"
  memory_size                    = 256
  publish                        = false
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.r2-lab-fn_role.arn
  runtime                        = "python3.13"
  source_code_hash               = data.archive_file.archive_Import_r2-lab-fn.output_base64sha256
  timeout                        = 120
  environment {
    variables = {
      NAME                        = "r2-lab-fn"
      REGION                      = data.aws_region.current.region
      ACCOUNT                     = data.aws_caller_identity.current.account_id
      R2_ENDPOINT                 = "https://bf9638139fc9b9a92fa0334ae15ac3ac.r2.cloudflarestorage.com"
      R2_CREDENTIALS_PARAMETER    = "/cross-cloud/r2lab/r2"
      CROSS_CLOUD_PARAMETER       = "/cross-cloud/r2lab/r2"
      CROSS_CLOUD_GATEWAY_URL     = "https://r2lab-gateway.rbpmconsulting.workers.dev"
      CLOUDFLARE_R2_BUCKET_NAME_0 = "r2-lab-phase3"
    }
  }
  tags = {
    Name           = "r2-lab-fn"
    State          = "stateR2LabAws"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_function_r2-lab-fn_st_stateR2LabAws_attach]
}
