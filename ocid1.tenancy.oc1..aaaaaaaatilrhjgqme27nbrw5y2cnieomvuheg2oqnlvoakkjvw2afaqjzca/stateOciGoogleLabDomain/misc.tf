# Deactivates the identity domain struct8-google-lab when it is destroyed or replaced.
# OCI does not delete an active identity domain.
resource "terraform_data" "struct8-google-lab_deactivate" {
  triggers_replace = "https://identity.sa-saopaulo-1.oci.oraclecloud.com/20160918/domains/${oci_identity_domain.struct8-google-lab.id}"
  provisioner "local-exec" {
    command = <<EOF
set -e
DOMAIN_URL="${self.triggers_replace}"
HOST="$(printf '%s' "$DOMAIN_URL" | sed -e 's|^https://||' -e 's|/.*||')"
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
  echo "No OCI credentials reach the machine that runs the destroy, and they deactivate the identity domain struct8-google-lab before it is deleted." >&2
  exit 1
fi
# send METHOD URL BODY: sets STATUS to the HTTP status and OUT to the response body.
send() {
  TARGET="/$(printf '%s' "$2" | sed -e 's|^https://[^/]*/||')"
  if [ "$MODE" = sign ]; then
    VERB="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    NOW="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT')"
    if [ "$1" = GET ]; then
      SIGNATURE="$(printf 'date: %s\n(request-target): %s %s\nhost: %s' "$NOW" "$VERB" "$TARGET" "$HOST" | openssl dgst -sha256 -sign "$PEM" | openssl base64 -A)"
      curl -sS -D "$HEAD" -o "$OUT" -H "date: $NOW" -H 'authorization: Signature version="1",keyId="ST$'"$RPST"'",algorithm="rsa-sha256",headers="date (request-target) host",signature="'"$SIGNATURE"'"' "$2"
    else
      SHA="$(printf '%s' "$3" | openssl dgst -sha256 -binary | openssl base64 -A)"
      LEN="$(printf '%s' "$3" | wc -c | tr -d ' ')"
      SIGNATURE="$(printf 'date: %s\n(request-target): %s %s\nhost: %s\nx-content-sha256: %s\ncontent-type: application/json\ncontent-length: %s' "$NOW" "$VERB" "$TARGET" "$HOST" "$SHA" "$LEN" | openssl dgst -sha256 -sign "$PEM" | openssl base64 -A)"
      curl -sS -X "$1" -D "$HEAD" -o "$OUT" -H "date: $NOW" -H "x-content-sha256: $SHA" -H "content-type: application/json" -H "content-length: $LEN" -H 'authorization: Signature version="1",keyId="ST$'"$RPST"'",algorithm="rsa-sha256",headers="date (request-target) host x-content-sha256 content-type content-length",signature="'"$SIGNATURE"'"' --data-binary "$3" "$2"
    fi
    STATUS="$(sed -n '1s/^HTTP[^ ]* \([0-9][0-9][0-9]\).*/\1/p' "$HEAD")"
  else
    if [ -z "$3" ]; then oci raw-request --http-method "$1" --target-uri "$2" > "$OUT" 2>&1 || true
    else oci raw-request --http-method "$1" --target-uri "$2" --request-body "$3" > "$OUT" 2>&1 || true
    fi
    STATUS="$(sed -n 's/.*"status": *"\([0-9][0-9][0-9]\).*/\1/p' "$OUT" | head -n 1)"
  fi
  }
REFUSED="$(mktemp)"; CLEAN="$CLEAN $REFUSED"
send POST "$DOMAIN_URL/actions/deactivate" ''
ACCEPTED="$STATUS"
case "$ACCEPTED" in
  200|202|204) echo "Deactivating the identity domain struct8-google-lab." ;;
  404) echo "Identity domain struct8-google-lab no longer exists."; exit 0 ;;
  *) cp "$OUT" "$REFUSED" ;;
esac
TRIES=0
while :; do
  send GET "$DOMAIN_URL" ''
  STATE="$(sed -n 's/.*"lifecycleState" *: *"\([A-Z_]*\)".*/\1/p' "$OUT" | head -n 1)"
  case "$STATUS/$STATE" in
    404/*) echo "Identity domain struct8-google-lab no longer exists."; exit 0 ;;
    200/INACTIVE) echo "Identity domain struct8-google-lab deactivated."; exit 0 ;;
    200/*) ;;
    *) cat "$OUT" >&2; echo "The state of the identity domain struct8-google-lab could not be read (HTTP $STATUS)." >&2; exit 1 ;;
  esac
  case "$ACCEPTED" in
    200|202|204) ;;
    *) cat "$REFUSED" >&2; echo "The identity domain struct8-google-lab refused the deactivation (HTTP $ACCEPTED)." >&2; exit 1 ;;
  esac
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge 120 ]; then echo "The identity domain struct8-google-lab did not read INACTIVE within 20 minutes." >&2; exit 1; fi
  sleep 10
done
    EOF
    interpreter = ["/bin/bash", "-c"]
    when        = destroy
  }
}
