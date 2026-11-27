resource "terraform_data" "wordpress1_image" {
  input = ["Canonical Ubuntu", "24.04", "arm64"]
}

# Deactivates the identity domain application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5 when it is destroyed or replaced.
# The identity domain does not delete an active application.
# It also removes the certificates of the application, which the identity domain would delete with it.
resource "terraform_data" "wp-debug1_debug_caller_deactivate" {
  triggers_replace = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com/admin/v1/AppStatusChanger/${oci_identity_domains_app.wp-debug1_debug_caller.id}"
  provisioner "local-exec" {
    command = <<EOF
set -e
APP_STATUS_URL="${self.triggers_replace}"
HOST="$(printf '%s' "$APP_STATUS_URL" | sed -e 's|^https://||' -e 's|/.*||')"
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
  echo "No OCI credentials reach the machine that runs the destroy, and they deactivate the application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5 before it is deleted." >&2
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
  200|204) echo "Application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5 deactivated." ;;
  404) echo "Application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5 no longer exists."; exit 0 ;;
  *) cat "$OUT" >&2; echo "The identity domain did not deactivate the application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5 (HTTP $STATUS)." >&2; exit 1 ;;
esac
send PATCH "$(printf '%s' "$APP_STATUS_URL" | sed -e 's|/AppStatusChanger/|/Apps/|')" '{"schemas":["urn:ietf:params:scim:api:messages:2.0:PatchOp"],"Operations":[{"op":"remove","path":"certificates"}]}'
case "$STATUS" in
  200|204) echo "Certificates removed from the application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5." ;;
  404) echo "Application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5 no longer exists." ;;
  *) cat "$OUT" >&2; echo "The identity domain did not remove the certificates from the application struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5 (HTTP $STATUS)." >&2; exit 1 ;;
esac
    EOF
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
  }
}
