resource "aws_ssm_parameter" "cross-link" {
  name        = "/cross-cloud/cross-link/google"
  description = "Google Cloud credential configuration that cross-caller reads to reach cross-gateway, cross-events, deft-landing-343414-cross-data, cross-secret. Written by the component cross-link."
  provider    = aws.acct_952133486861
  type        = "String"
  value       = jsonencode({ type = "external_account", audience = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.cross-link.name}", subject_token_type = "urn:ietf:params:aws:token-type:aws4_request", token_url = "https://sts.googleapis.com/v1/token", service_account_impersonation_url = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${google_service_account.cross-link.email}:generateAccessToken", credential_source = { environment_id = "aws1", region_url = "http://169.254.169.254/latest/meta-data/placement/availability-zone", url = "http://169.254.169.254/latest/meta-data/iam/security-credentials", regional_cred_verification_url = "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15" } })
}
