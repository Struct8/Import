# lab/cloudshell-oci-google.sh
#
# OCI Cloud Shell side of the lab in lab/oci-google-reader (an OCI function that
# reads and writes a Cloud Storage bucket through a cldmn_workload_identity
# component, direction 10).
# Run in the Cloud Shell of the rbpmconsulting tenancy, signed in as an
# administrator:
#
#   bash cloudshell-oci-google.sh domain            create the identity domain
#                                                struct8-google-lab, set its issuer
#                                                to its own URL, publish its
#                                                signing certificate, print the URL
#   bash cloudshell-oci-google.sh invoke <action>   invoke the lab function with
#                                                {"action": "<action>"}
#   bash cloudshell-oci-google.sh cleanup-domain    deactivate and delete the domain
#
# Why a domain of its own: the issuer change applies to every token the
# domain signs, and the Default domain signs for the GitHub federation of every
# OCI apply. Nothing here holds a key or a secret.
set -euo pipefail
NAME="struct8-google-lab"
FUNCTION_NAME="${FUNCTION_NAME:-oci-google-reader}"
COMPARTMENT_NAME="${COMPARTMENT_NAME:-lab-oci-google}"
TENANCY="${TENANCY:-${OCI_TENANCY:-}}"
export OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING=True
if [ -z "$TENANCY" ]; then echo "Set TENANCY to the tenancy OCID." >&2; exit 1; fi
REGION="$(oci iam region-subscription list --tenancy-id "$TENANCY" --query 'data[?"is-home-region"]."region-name" | [0]' --raw-output)"
export NAME

json_value() { python3 -c 'import json, sys
raw = sys.stdin.read()
d = json.loads(raw) if raw.strip() else {}
v = eval(sys.argv[1])
print("" if v is None else v)' "$1"; }

domain_field() {
  oci iam domain list --region "$REGION" --compartment-id "$TENANCY" --all --output json \
    | json_value "([x[\"$1\"] for x in d.get(\"data\", []) if x[\"display-name\"] == __import__(\"os\").environ[\"NAME\"] and x[\"lifecycle-state\"] != \"DELETED\"] or [\"\"])[0]"
}

domain_call() {
  local response
  if [ $# -ge 3 ]; then
    response="$(printf '%s' "$3" | oci raw-request --region "$REGION" --http-method "$1" --target-uri "$DOMAIN_URL$2" --request-body file:///dev/stdin)"
  else
    response="$(oci raw-request --region "$REGION" --http-method "$1" --target-uri "$DOMAIN_URL$2")"
  fi
  printf '%s' "$response" | python3 -c 'import json, sys
r = json.load(sys.stdin)
status = str(r.get("status", ""))
if not status.startswith("2"):
    sys.stderr.write("The identity domain refused the request: " + status + " " + json.dumps(r.get("data"))[:400] + "\n")
    sys.exit(1)
print(json.dumps(r.get("data")))'
}

wait_domain() {
  local state=""
  for _ in $(seq 1 90); do
    state="$(domain_field lifecycle-state)"
    [ "$state" = "$1" ] && return 0
    [ -z "$state" ] && [ "$1" = "GONE" ] && return 0
    sleep 20
  done
  echo "The domain $NAME did not reach $1 in 30 minutes (state: ${state:-none})." >&2
  return 1
}

case "${1:-}" in
domain)
  if [ -z "$(domain_field id)" ]; then
    echo "Creating the identity domain $NAME (type free; this takes a few minutes)..."
    oci iam domain create --region "$REGION" --compartment-id "$TENANCY" --display-name "$NAME" \
      --description "Struct8 lab: OCI identity domain as the OIDC provider of Google STS for an OCI function. Delete with lab/cloudshell-oci-google.sh cleanup-domain." \
      --home-region "$REGION" --license-type free --is-notification-bypassed true >/dev/null
  fi
  wait_domain ACTIVE
  DOMAIN_URL="$(oci iam domain get --region "$REGION" --domain-id "$(domain_field id)" --query 'data.url' --raw-output | sed -e 's#/*$##' -e 's#:443$##')"
  export DOMAIN_URL
  domain_call PATCH "/admin/v1/Settings/Settings" "$(python3 -c 'import json, os; print(json.dumps({"schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"], "Operations": [
    {"op": "replace", "path": "issuer", "value": os.environ["DOMAIN_URL"]},
    {"op": "replace", "path": "signingCertPublicAccess", "value": True}]}))')" >/dev/null
  echo "Settings: $(domain_call GET "/admin/v1/Settings/Settings?attributes=issuer,signingCertPublicAccess" | json_value '"issuer=%s signingCertPublicAccess=%s" % (d.get("issuer"), d.get("signingCertPublicAccess"))')"
  echo "Discovery without login: HTTP $(curl -s -o /tmp/lab-discovery.json -w '%{http_code}' "$DOMAIN_URL/.well-known/openid-configuration") $(json_value '"issuer=%s" % d.get("issuer")' < /tmp/lab-discovery.json 2>/dev/null || true)"
  echo "Signing keys without login: HTTP $(curl -s -o /dev/null -w '%{http_code}' "$DOMAIN_URL/admin/v1/SigningCert/jwk")"
  echo "DOMAIN_URL=$DOMAIN_URL"
  ;;
invoke)
  ACTION="${2:-test}"
  COMPARTMENT_ID="$(oci iam compartment list --compartment-id "$TENANCY" --compartment-id-in-subtree true --all --lifecycle-state ACTIVE --output json \
    | COMPARTMENT_NAME="$COMPARTMENT_NAME" json_value '([x["id"] for x in d.get("data", []) if x["name"].startswith(__import__("os").environ["COMPARTMENT_NAME"])] or [""])[0]')"
  if [ -z "$COMPARTMENT_ID" ]; then echo "No compartment named $COMPARTMENT_NAME." >&2; exit 1; fi
  FUNCTION_ID=""
  for APP_ID in $(oci fn application list --compartment-id "$COMPARTMENT_ID" --all --lifecycle-state ACTIVE --query 'data[].id' --raw-output | tr -d '[],"'); do
    FUNCTION_ID="$(oci fn function list --application-id "$APP_ID" --all --lifecycle-state ACTIVE --output json \
      | FUNCTION_NAME="$FUNCTION_NAME" json_value '([x["id"] for x in d.get("data", []) if x["display-name"].startswith(__import__("os").environ["FUNCTION_NAME"])] or [""])[0]')"
    [ -n "$FUNCTION_ID" ] && break
  done
  if [ -z "$FUNCTION_ID" ]; then echo "No function named $FUNCTION_NAME in $COMPARTMENT_NAME." >&2; exit 1; fi
  oci fn function invoke --function-id "$FUNCTION_ID" --file "-" --body "{\"action\": \"$ACTION\"}"
  echo
  ;;
cleanup-domain)
  DOMAIN_ID="$(domain_field id)"
  if [ -z "$DOMAIN_ID" ]; then echo "No domain $NAME."; exit 0; fi
  if [ "$(domain_field lifecycle-state)" = "ACTIVE" ] && [ "$(oci iam domain get --region "$REGION" --domain-id "$DOMAIN_ID" --query 'data."lifecycle-details"' --raw-output 2>/dev/null)" != "DEACTIVATED" ]; then
    echo "Deactivating $NAME..."
    oci iam domain deactivate --region "$REGION" --domain-id "$DOMAIN_ID" --is-notification-bypassed true >/dev/null || true
    sleep 60
  fi
  echo "Deleting $NAME..."
  oci iam domain delete --region "$REGION" --domain-id "$DOMAIN_ID" --is-notification-bypassed true --force >/dev/null
  wait_domain GONE
  echo "Deleted."
  ;;
*)
  echo "Usage: bash cloudshell-oci-google.sh domain | invoke <action> | cleanup-domain" >&2
  exit 1
  ;;
esac
