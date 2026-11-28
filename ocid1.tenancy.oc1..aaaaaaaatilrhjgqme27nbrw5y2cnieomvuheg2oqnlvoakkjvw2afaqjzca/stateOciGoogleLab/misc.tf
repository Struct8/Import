# Deactivates the identity domain application oci-gcs-reader when it is destroyed or replaced.
# The identity domain does not delete an active application.
# It also removes the certificates of the application, which the identity domain would delete with it.
resource "terraform_data" "oci-google-reader_google_deactivate" {
  triggers_replace = "${one([for it in data.oci_identity_domains.struct8-google-lab.domains : it.url if it.display_name == "struct8-google-lab"])}/admin/v1/AppStatusChanger/${oci_identity_domains_app.oci-google-reader_google.id}"
  provisioner "local-exec" {
    command = <<EOF
set -e
APP_STATUS_URL="${self.triggers_replace}"
HOST="$(printf '%s' "$APP_STATUS_URL" | sed -e 's|^https://||' -e 's|/.*||' -e 's|:443$||')"
OUT="$(mktemp)"; HEAD="$(mktemp)"; CLEAN="$OUT $HEAD"
trap 'rm -f $CLEAN' EXIT
if [ -n "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then
  MODE=sign
  if [ -f "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then RPST="$(cat "$OCI_RESOURCE_PRINCIPAL_RPST")"; else RPST="$OCI_RESOURCE_PRINCIPAL_RPST"; fi
  PEM="$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM"
  if [ ! -f "$PEM" ]; then PEM="$(mktemp)"; CLEAN="$CLEAN $PEM"; printf '%s\n' "$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM" > "$PEM"; fi
elif command -v oci > /dev/null 2>&1; then
  MODE=cli
else
  echo "No OCI credentials reach the machine that runs the destroy, and they deactivate the application oci-gcs-reader before it is deleted." >&2
  exit 1
fi
# send METHOD URL BODY: sets STATUS to the HTTP status and OUT to the response body.
send() {
  TARGET="/$(printf '%s' "$2" | sed -e 's|^https://[^/]*/||')"
  if [ "$MODE" = sign ]; then
    VERB="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    NOW="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT')"
    SHA="$(printf '%s' "$3" | openssl dgst -sha256 -binary | openssl base64 -A)"
    LEN="$(printf '%s' "$3" | wc -c | tr -d ' ')"
    SIGNATURE="$(printf 'date: %s\n(request-target): %s %s\nhost: %s\nx-content-sha256: %s\ncontent-type: application/json\ncontent-length: %s' "$NOW" "$VERB" "$TARGET" "$HOST" "$SHA" "$LEN" | openssl dgst -sha256 -sign "$PEM" | openssl base64 -A)"
    curl -sS -X "$1" -D "$HEAD" -o "$OUT" -H "date: $NOW" -H "x-content-sha256: $SHA" -H "content-type: application/json" -H "content-length: $LEN" -H 'authorization: Signature version="1",keyId="ST$'"$RPST"'",algorithm="rsa-sha256",headers="date (request-target) host x-content-sha256 content-type content-length",signature="'"$SIGNATURE"'"' --data-binary "$3" "$2"
    STATUS="$(sed -n '1s/^HTTP[^ ]* \([0-9][0-9][0-9]\).*/\1/p' "$HEAD")"
  else
    oci raw-request --http-method "$1" --target-uri "$2" --request-body "$3" > "$OUT" 2>&1 || true
    STATUS="$(sed -n 's/.*"status": *"\([0-9][0-9][0-9]\).*/\1/p' "$OUT" | head -n 1)"
  fi
  }
send PUT "$APP_STATUS_URL" '{"active":false,"schemas":["urn:ietf:params:scim:schemas:oracle:idcs:AppStatusChanger"]}'
case "$STATUS" in
  200|204) echo "Application oci-gcs-reader deactivated." ;;
  404) echo "Application oci-gcs-reader no longer exists."; exit 0 ;;
  *) cat "$OUT" >&2; echo "The identity domain did not deactivate the application oci-gcs-reader (HTTP $STATUS)." >&2; exit 1 ;;
esac
send PATCH "$(printf '%s' "$APP_STATUS_URL" | sed -e 's|/AppStatusChanger/|/Apps/|')" '{"schemas":["urn:ietf:params:scim:api:messages:2.0:PatchOp"],"Operations":[{"op":"remove","path":"certificates"}]}'
case "$STATUS" in
  200|204) echo "Certificates removed from the application oci-gcs-reader." ;;
  404) echo "Application oci-gcs-reader no longer exists." ;;
  *) cat "$OUT" >&2; echo "The identity domain did not remove the certificates from the application oci-gcs-reader (HTTP $STATUS)." >&2; exit 1 ;;
esac
    EOF
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
  }
}

# Deactivates the identity domain application oci-gcs-reader-sts when it is destroyed or replaced.
# The identity domain does not delete an active application.
resource "terraform_data" "oci-google-reader_google_sts_deactivate" {
  triggers_replace = "${one([for it in data.oci_identity_domains.struct8-google-lab.domains : it.url if it.display_name == "struct8-google-lab"])}/admin/v1/AppStatusChanger/${oci_identity_domains_app.oci-google-reader_google_sts.id}"
  provisioner "local-exec" {
    command = <<EOF
set -e
APP_STATUS_URL="${self.triggers_replace}"
HOST="$(printf '%s' "$APP_STATUS_URL" | sed -e 's|^https://||' -e 's|/.*||' -e 's|:443$||')"
OUT="$(mktemp)"; HEAD="$(mktemp)"; CLEAN="$OUT $HEAD"
trap 'rm -f $CLEAN' EXIT
if [ -n "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then
  MODE=sign
  if [ -f "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then RPST="$(cat "$OCI_RESOURCE_PRINCIPAL_RPST")"; else RPST="$OCI_RESOURCE_PRINCIPAL_RPST"; fi
  PEM="$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM"
  if [ ! -f "$PEM" ]; then PEM="$(mktemp)"; CLEAN="$CLEAN $PEM"; printf '%s\n' "$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM" > "$PEM"; fi
elif command -v oci > /dev/null 2>&1; then
  MODE=cli
else
  echo "No OCI credentials reach the machine that runs the destroy, and they deactivate the application oci-gcs-reader-sts before it is deleted." >&2
  exit 1
fi
# send METHOD URL BODY: sets STATUS to the HTTP status and OUT to the response body.
send() {
  TARGET="/$(printf '%s' "$2" | sed -e 's|^https://[^/]*/||')"
  if [ "$MODE" = sign ]; then
    VERB="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    NOW="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT')"
    SHA="$(printf '%s' "$3" | openssl dgst -sha256 -binary | openssl base64 -A)"
    LEN="$(printf '%s' "$3" | wc -c | tr -d ' ')"
    SIGNATURE="$(printf 'date: %s\n(request-target): %s %s\nhost: %s\nx-content-sha256: %s\ncontent-type: application/json\ncontent-length: %s' "$NOW" "$VERB" "$TARGET" "$HOST" "$SHA" "$LEN" | openssl dgst -sha256 -sign "$PEM" | openssl base64 -A)"
    curl -sS -X "$1" -D "$HEAD" -o "$OUT" -H "date: $NOW" -H "x-content-sha256: $SHA" -H "content-type: application/json" -H "content-length: $LEN" -H 'authorization: Signature version="1",keyId="ST$'"$RPST"'",algorithm="rsa-sha256",headers="date (request-target) host x-content-sha256 content-type content-length",signature="'"$SIGNATURE"'"' --data-binary "$3" "$2"
    STATUS="$(sed -n '1s/^HTTP[^ ]* \([0-9][0-9][0-9]\).*/\1/p' "$HEAD")"
  else
    oci raw-request --http-method "$1" --target-uri "$2" --request-body "$3" > "$OUT" 2>&1 || true
    STATUS="$(sed -n 's/.*"status": *"\([0-9][0-9][0-9]\).*/\1/p' "$OUT" | head -n 1)"
  fi
  }
send PUT "$APP_STATUS_URL" '{"active":false,"schemas":["urn:ietf:params:scim:schemas:oracle:idcs:AppStatusChanger"]}'
case "$STATUS" in
  200|204) echo "Application oci-gcs-reader-sts deactivated." ;;
  404) echo "Application oci-gcs-reader-sts no longer exists."; exit 0 ;;
  *) cat "$OUT" >&2; echo "The identity domain did not deactivate the application oci-gcs-reader-sts (HTTP $STATUS)." >&2; exit 1 ;;
esac
    EOF
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
  }
}

resource "terraform_data" "seed_oci-google-reader" {
  input            = substr(sha1(jsonencode({ for f in fileset(join("/", [path.module, ".external_modules/Import/lab/oci-google-reader"]), "**") : f => filesha1(join("/", [path.module, ".external_modules/Import/lab/oci-google-reader", f])) })), 0, 12)
  triggers_replace = ["${path.module}/.external_modules/Import/lab/oci-google-reader", substr(sha1(jsonencode({ for f in fileset(join("/", [path.module, ".external_modules/Import/lab/oci-google-reader"]), "**") : f => filesha1(join("/", [path.module, ".external_modules/Import/lab/oci-google-reader", f])) })), 0, 12)]
  lifecycle {
    replace_triggered_by = [oci_artifacts_container_repository.oci-google-reader]
  }
  depends_on = [oci_artifacts_container_repository.oci-google-reader]
  provisioner "local-exec" {
    command = <<EOF
set -e
command -v docker > /dev/null 2>&1 || { echo "Docker is not installed on the machine that runs the apply, and the image of oci-google-reader is built there." >&2; exit 1; }
REGISTRY=gru.ocir.io
if [ -n "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then
  if [ -f "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then RPST="$(cat "$OCI_RESOURCE_PRINCIPAL_RPST")"; else RPST="$OCI_RESOURCE_PRINCIPAL_RPST"; fi
  PEM="$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM"
  if [ ! -f "$PEM" ]; then PEM="$(mktemp)"; trap 'rm -f "$PEM"' EXIT; printf '%s\n' "$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM" > "$PEM"; fi
  NOW="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT')"
  SIGNATURE="$(printf 'date: %s\n(request-target): get /20180419/docker/token\nhost: %s' "$NOW" "$REGISTRY" | openssl dgst -sha256 -sign "$PEM" | openssl base64 -A)"
  RESPONSE="$(curl -fsS -H "date: $NOW" -H 'authorization: Signature version="1",keyId="ST$'"$RPST"'",algorithm="rsa-sha256",headers="date (request-target) host",signature="'"$SIGNATURE"'"' "https://$REGISTRY/20180419/docker/token")"
elif command -v oci > /dev/null 2>&1; then
  RESPONSE="$(oci raw-request --http-method GET --target-uri "https://$REGISTRY/20180419/docker/token")"
else
  echo "No OCI credentials reach the machine that runs the apply, and they sign Docker in to oci-google-reader." >&2
  exit 1
fi
TOKEN="$(printf '%s' "$RESPONSE" | sed -n 's/.*"token" *: *"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$TOKEN" ] || { echo "Container Registry returned no token to sign Docker in to oci-google-reader." >&2; exit 1; }
printf '%s' "$TOKEN" | docker login --username BEARER_TOKEN --password-stdin "$REGISTRY"
docker build --provenance=false --platform linux/amd64 -t gru.ocir.io/${oci_artifacts_container_repository.oci-google-reader.namespace}/${oci_artifacts_container_repository.oci-google-reader.display_name}:${self.input} ${path.module}/.external_modules/Import/lab/oci-google-reader
docker push gru.ocir.io/${oci_artifacts_container_repository.oci-google-reader.namespace}/${oci_artifacts_container_repository.oci-google-reader.display_name}:${self.input}
    EOF
    interpreter = ["/bin/bash", "-c"]
  }
}
