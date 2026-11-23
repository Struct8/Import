# Empties the R2 bucket r2-lab-phase4 when this state is destroyed, so that the destroy can delete it (Force destroy on the bucket).
# The command runs only under terraform destroy; it does nothing on apply.
# R2 has an S3-compatible API: the aws CLI is only the S3 client, pointed at the R2 endpoint,
# and the AWS_* variables carry the short-lived R2 token of this run. No AWS account is used.
resource "terraform_data" "r2-lab-phase4-empty-on-destroy" {
  input = {
    account_id  = cloudflare_r2_bucket.r2-lab-phase4.account_id
    bucket_name = cloudflare_r2_bucket.r2-lab-phase4.name
    s3_host     = "r2.cloudflarestorage.com"
  }
  provisioner "local-exec" {
    command = <<EOF
log() { echo "force_destroy_ $BUCKET: $*"; }
seen=0; subcommand=''; destroy_flag=0
while IFS= read -r -d '' arg; do
  if [ $seen -eq 0 ]; then
    case "$arg" in terraform|*/terraform|terraform-bin|*/terraform-bin|tofu|*/tofu) seen=1 ;; esac
    continue
  fi
  case "$arg" in
    -destroy) destroy_flag=1 ;;
    -*) ;;
    *) [ -z "$subcommand" ] && subcommand="$arg" ;;
  esac
done < /proc/$PPID/cmdline
if [ "$subcommand" != destroy ] && ! { [ "$subcommand" = apply ] && [ $destroy_flag -eq 1 ]; }; then
  log "not called by terraform destroy (subcommand: $subcommand), so no object was deleted."
  exit 0
fi
if [ -z "$TF_VAR_r2_access_key_id" ] || [ -z "$TF_VAR_r2_secret_access_key" ]; then
  log "no R2 credential in the environment, so no object was deleted."
  exit 0
fi
unset AWS_PROFILE AWS_DEFAULT_PROFILE AWS_SESSION_TOKEN
export AWS_ACCESS_KEY_ID="$TF_VAR_r2_access_key_id"
export AWS_SECRET_ACCESS_KEY="$TF_VAR_r2_secret_access_key"
export AWS_REGION=auto AWS_DEFAULT_REGION=auto
export AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED AWS_RESPONSE_CHECKSUM_VALIDATION=WHEN_REQUIRED
endpoint="https://$ACCOUNT_ID.$S3_HOST"
aws s3api list-multipart-uploads --bucket "$BUCKET" --endpoint-url "$endpoint" --query 'Uploads[].[Key,UploadId]' --output text 2>/dev/null |
  while read -r key id; do
    [ -n "$id" ] && [ "$key" != "None" ] && aws s3api abort-multipart-upload --bucket "$BUCKET" --key "$key" --upload-id "$id" --endpoint-url "$endpoint" >/dev/null 2>&1
  done
attempt=1
while [ $attempt -le 24 ]; do
  if out=$(aws s3 rm "s3://$BUCKET" --recursive --endpoint-url "$endpoint" 2>&1); then
    log "emptied, $(printf %s "$out" | grep -c "^delete:") object(s) deleted."
    exit 0
  fi
  case "$out" in
    *NoSuchBucket*) log "the bucket no longer exists."; exit 0 ;;
    *Unauthorized*|*InvalidAccessKeyId*) sleep 5; attempt=$((attempt + 1)) ;;
    *) break ;;
  esac
done
printf "%s\n" "$out" >&2
log "could not empty the bucket."
exit 1
    EOF
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
    environment = {
      ACCOUNT_ID = self.input.account_id
      BUCKET     = self.input.bucket_name
      S3_HOST    = self.input.s3_host
    }
  }
}

# Empties the R2 bucket r2-lab-phase4-other when this state is destroyed, so that the destroy can delete it (Force destroy on the bucket).
# The command runs only under terraform destroy; it does nothing on apply.
# R2 has an S3-compatible API: the aws CLI is only the S3 client, pointed at the R2 endpoint,
# and the AWS_* variables carry the short-lived R2 token of this run. No AWS account is used.
resource "terraform_data" "r2-lab-phase4-other-empty-on-destroy" {
  input = {
    account_id  = cloudflare_r2_bucket.r2-lab-phase4-other.account_id
    bucket_name = cloudflare_r2_bucket.r2-lab-phase4-other.name
    s3_host     = "r2.cloudflarestorage.com"
  }
  provisioner "local-exec" {
    command = <<EOF
log() { echo "force_destroy_ $BUCKET: $*"; }
seen=0; subcommand=''; destroy_flag=0
while IFS= read -r -d '' arg; do
  if [ $seen -eq 0 ]; then
    case "$arg" in terraform|*/terraform|terraform-bin|*/terraform-bin|tofu|*/tofu) seen=1 ;; esac
    continue
  fi
  case "$arg" in
    -destroy) destroy_flag=1 ;;
    -*) ;;
    *) [ -z "$subcommand" ] && subcommand="$arg" ;;
  esac
done < /proc/$PPID/cmdline
if [ "$subcommand" != destroy ] && ! { [ "$subcommand" = apply ] && [ $destroy_flag -eq 1 ]; }; then
  log "not called by terraform destroy (subcommand: $subcommand), so no object was deleted."
  exit 0
fi
if [ -z "$TF_VAR_r2_access_key_id" ] || [ -z "$TF_VAR_r2_secret_access_key" ]; then
  log "no R2 credential in the environment, so no object was deleted."
  exit 0
fi
unset AWS_PROFILE AWS_DEFAULT_PROFILE AWS_SESSION_TOKEN
export AWS_ACCESS_KEY_ID="$TF_VAR_r2_access_key_id"
export AWS_SECRET_ACCESS_KEY="$TF_VAR_r2_secret_access_key"
export AWS_REGION=auto AWS_DEFAULT_REGION=auto
export AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED AWS_RESPONSE_CHECKSUM_VALIDATION=WHEN_REQUIRED
endpoint="https://$ACCOUNT_ID.$S3_HOST"
aws s3api list-multipart-uploads --bucket "$BUCKET" --endpoint-url "$endpoint" --query 'Uploads[].[Key,UploadId]' --output text 2>/dev/null |
  while read -r key id; do
    [ -n "$id" ] && [ "$key" != "None" ] && aws s3api abort-multipart-upload --bucket "$BUCKET" --key "$key" --upload-id "$id" --endpoint-url "$endpoint" >/dev/null 2>&1
  done
attempt=1
while [ $attempt -le 24 ]; do
  if out=$(aws s3 rm "s3://$BUCKET" --recursive --endpoint-url "$endpoint" 2>&1); then
    log "emptied, $(printf %s "$out" | grep -c "^delete:") object(s) deleted."
    exit 0
  fi
  case "$out" in
    *NoSuchBucket*) log "the bucket no longer exists."; exit 0 ;;
    *Unauthorized*|*InvalidAccessKeyId*) sleep 5; attempt=$((attempt + 1)) ;;
    *) break ;;
  esac
done
printf "%s\n" "$out" >&2
log "could not empty the bucket."
exit 1
    EOF
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
    environment = {
      ACCOUNT_ID = self.input.account_id
      BUCKET     = self.input.bucket_name
      S3_HOST    = self.input.s3_host
    }
  }
}
