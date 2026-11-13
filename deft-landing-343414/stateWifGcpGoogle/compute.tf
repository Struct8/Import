resource "google_cloud_run_v2_job" "wif-lab-job" {
  name                  = "wif-lab-job"
  deletion_protection   = false
  location              = "us-central1"
  start_execution_token = "wif-lab-run-1"
  labels = {
    struct8_state   = "statewifgcpgoogle"
    struct8_creator = "contato_struct"
  }
  template {
    parallelism = 1
    task_count  = 1
    template {
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      max_retries           = 0
      service_account       = google_service_account.wif-lab-job_sa.email
      containers {
        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
        args = [
          <<EOF
MD=http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default
claims() { p=$(cut -d. -f2 "$1" | tr '_-' '/+'); case $(( $(printf %s "$p" | wc -c) % 4 )) in 2) p="$p==";; 3) p="$p=";; esac; printf %s "$p" | base64 -d; echo; }
echo "== env: AWS_ROLE_ARN=$AWS_ROLE_ARN AWS_REGION=$AWS_REGION OIDC_AUDIENCE=$OIDC_AUDIENCE BUCKET=$AWS_S3_BUCKET_NAME_0"
curl -sf -H "Metadata-Flavor: Google" "$MD/identity?audience=$OIDC_AUDIENCE&format=full" > /tmp/token || { echo "FAIL: no ID token"; exit 1; }
echo "== claims of the ID token (the token itself is not printed):"; claims /tmp/token
export AWS_WEB_IDENTITY_TOKEN_FILE=/tmp/token AWS_ROLE_SESSION_NAME=wif-lab
echo "== caller identity:"; aws sts get-caller-identity || { echo "FAIL: assume role"; exit 1; }
echo "written by the Cloud Run job at $(date -u +%FT%TZ)" > /tmp/proof.txt
aws s3 cp /tmp/proof.txt "s3://$AWS_S3_BUCKET_NAME_0/wif-lab/proof.txt" || { echo "FAIL: s3 put"; exit 1; }
echo "== bucket listing:"; aws s3 ls "s3://$AWS_S3_BUCKET_NAME_0/wif-lab/" || { echo "FAIL: s3 list"; exit 1; }
curl -sf -H "Metadata-Flavor: Google" "$MD/identity?audience=https://example.com&format=full" > /tmp/badtoken
if AWS_WEB_IDENTITY_TOKEN_FILE=/tmp/badtoken aws sts get-caller-identity > /tmp/bad.out 2>&1; then echo "FAIL: wrong audience was accepted"; exit 1; fi
echo "== wrong audience refused, as expected:"; tail -n 2 /tmp/bad.out
echo "PASS"
          EOF
        ]
        command = ["/bin/sh", "-c"]
        image   = "docker.io/amazon/aws-cli:latest"
        env {
          name  = "NAME"
          value = "wif-lab-job"
        }
        env {
          name  = "OIDC_AUDIENCE"
          value = "sts.amazonaws.com"
        }
        env {
          name  = "AWS_ROLE_ARN"
          value = "arn:aws:iam::952133486861:role/wif-gcp-lab"
        }
        env {
          name  = "AWS_REGION"
          value = "us-east-1"
        }
        env {
          name  = "AWS_S3_BUCKET_NAME_0"
          value = "wif-gcp-lab-proof-952133486861-us-east-1-an"
        }
      }
    }
  }
  depends_on = [google_project_service.run]
}
