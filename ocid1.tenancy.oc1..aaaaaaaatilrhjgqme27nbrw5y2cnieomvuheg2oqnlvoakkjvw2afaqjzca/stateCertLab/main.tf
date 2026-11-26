# Lab of option 1 (certificate by Terraform). Temporary: deleted with the lab.

locals {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaa43jynpdmus6zzoz2wkq5jvu3ei23cbsopuq33nwrwemo6ugqb4fq"
  latin1         = "ISO-8859-1"
  audience       = "struct8-cert-lab"

  # Fixed DER pieces of a self-signed certificate for an RSA 2048 key: CN=struct8-cert-lab,
  # serial 1, valid 2026-01-01 to 2036-01-01, sha256WithRSAEncryption, no extensions.
  tbs_head  = "MIIBl6ADAgECAgEBMA0GCSqGSIb3DQEBCwUAMBsxGTAXBgNVBAMMEHN0cnVjdDgtY2VydC1sYWIwHhcNMjYwMTAxMDAwMDAwWhcNMzYwMTAxMDAwMDAwWjAbMRkwFwYDVQQDDBBzdHJ1Y3Q4LWNlcnQtbGFi"
  cert_head = "MIICrw=="
  cert_tail = "MA0GCSqGSIb3DQEBCwUAA4IBAQA="

  # SubjectPublicKeyInfo of the Vault key, from its PEM.
  spki = replace(replace(data.oci_kms_key_version.current.public_key, "/-----[A-Z ]+-----/", ""), "/[\\r\\n ]/", "")
  tbs  = textencodebase64(join("", [for p in [local.tbs_head, local.spki] : textdecodebase64(p, local.latin1)]), local.latin1)
  certificate = textencodebase64(join("", [for p in [local.cert_head, local.tbs_head, local.spki, local.cert_tail, oci_kms_sign.certificate.signature] : textdecodebase64(p, local.latin1)]), local.latin1)

  # The identity domain's address, without the :443 the provider may append.
  domain_url = trimsuffix(trimsuffix(oci_identity_domain.lab.url, "/"), ":443")
}

resource "oci_kms_vault" "lab" {
  compartment_id = local.compartment_id
  display_name   = "struct8-cert-lab"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "lab" {
  compartment_id      = local.compartment_id
  display_name        = "struct8-cert-lab"
  management_endpoint = oci_kms_vault.lab.management_endpoint
  protection_mode     = "HSM"
  key_shape {
    algorithm = "RSA"
    length    = 256
  }
}

data "oci_kms_key_version" "current" {
  key_id              = oci_kms_key.lab.id
  key_version_id      = oci_kms_key.lab.current_key_version
  management_endpoint = oci_kms_vault.lab.management_endpoint
}

# The Vault signs the TBSCertificate; Terraform never holds the private key.
resource "oci_kms_sign" "certificate" {
  crypto_endpoint   = oci_kms_vault.lab.crypto_endpoint
  key_id            = oci_kms_key.lab.id
  key_version_id    = oci_kms_key.lab.current_key_version
  message           = local.tbs
  message_type      = "RAW"
  signing_algorithm = "SHA_256_RSA_PKCS1_V1_5"

  lifecycle {
    precondition {
      condition     = length(local.spki) == 392
      error_message = "The public key of the Vault key is not the 294-byte SubjectPublicKeyInfo of an RSA 2048 key with exponent 65537."
    }
  }
}

resource "oci_identity_domain" "lab" {
  compartment_id     = local.compartment_id
  display_name       = "struct8-cert-lab"
  description        = "Lab of the certificate assembled by Terraform. Temporary."
  home_region        = "sa-saopaulo-1"
  license_type       = "free"
  is_hidden_on_login = true
}

# Destroyed after every resource inside the domain and before the domain: OCI deletes only a
# deactivated domain, and the provider does not deactivate it.
resource "terraform_data" "domain_guard" {
  input            = local.domain_url
  triggers_replace = "https://identity.sa-saopaulo-1.oci.oraclecloud.com/20160918/domains/${oci_identity_domain.lab.id}"

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e
      DOMAIN_URL="${self.triggers_replace}"
      HOST="$(printf '%s' "$DOMAIN_URL" | sed -e 's|^https://||' -e 's|/.*||')"
      OUT="$(mktemp)"; HEAD="$(mktemp)"; CLEAN="$OUT $HEAD"
      trap 'rm -f $CLEAN' EXIT
      if [ -z "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then
        echo "No OCI resource principal reaches the machine that runs the destroy, and it deactivates the identity domain struct8-cert-lab before it is deleted." >&2
        exit 1
      fi
      if [ -f "$OCI_RESOURCE_PRINCIPAL_RPST" ]; then RPST="$(cat "$OCI_RESOURCE_PRINCIPAL_RPST")"; else RPST="$OCI_RESOURCE_PRINCIPAL_RPST"; fi
      PEM="$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM"
      if [ ! -f "$PEM" ]; then PEM="$(mktemp)"; CLEAN="$CLEAN $PEM"; printf '%s\n' "$OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM" > "$PEM"; fi
      # send METHOD URL [BODY]: sets STATUS to the HTTP status and OUT to the response body.
      send() {
        TARGET="/$(printf '%s' "$2" | sed -e 's|^https://[^/]*/||')"
        VERB="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
        NOW="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT')"
        if [ "$1" = GET ]; then
          SIGNATURE="$(printf 'date: %s\n(request-target): %s %s\nhost: %s' "$NOW" "$VERB" "$TARGET" "$HOST" | openssl dgst -sha256 -sign "$PEM" | openssl base64 -A)"
          curl -sS -X GET -D "$HEAD" -o "$OUT" -H "date: $NOW" -H 'authorization: Signature version="1",keyId="ST$'"$RPST"'",algorithm="rsa-sha256",headers="date (request-target) host",signature="'"$SIGNATURE"'"' "$2"
        else
          SHA="$(printf '%s' "$3" | openssl dgst -sha256 -binary | openssl base64 -A)"
          LEN="$(printf '%s' "$3" | wc -c | tr -d ' ')"
          SIGNATURE="$(printf 'date: %s\n(request-target): %s %s\nhost: %s\nx-content-sha256: %s\ncontent-type: application/json\ncontent-length: %s' "$NOW" "$VERB" "$TARGET" "$HOST" "$SHA" "$LEN" | openssl dgst -sha256 -sign "$PEM" | openssl base64 -A)"
          curl -sS -X "$1" -D "$HEAD" -o "$OUT" -H "date: $NOW" -H "x-content-sha256: $SHA" -H "content-type: application/json" -H "content-length: $LEN" -H 'authorization: Signature version="1",keyId="ST$'"$RPST"'",algorithm="rsa-sha256",headers="date (request-target) host x-content-sha256 content-type content-length",signature="'"$SIGNATURE"'"' --data-binary "$3" "$2"
        fi
        STATUS="$(sed -n '1s/^HTTP[^ ]* \([0-9][0-9][0-9]\).*/\1/p' "$HEAD")"
      }
      state() {
        STATE="$(tr -d '\n' < "$OUT" | sed -n 's/.*"lifecycleState" *: *"\([A-Z_]*\)".*/\1/p')"
        DETAILS="$(tr -d '\n' < "$OUT" | sed -n 's/.*"lifecycleDetails" *: *"\([A-Z_]*\)".*/\1/p')"
      }
      send GET "$DOMAIN_URL"
      case "$STATUS" in
        200) state; echo "Identity domain struct8-cert-lab: $STATE $DETAILS." ;;
        404) echo "The identity domain struct8-cert-lab no longer exists."; exit 0 ;;
        *) cat "$OUT" >&2; echo "Reading the identity domain struct8-cert-lab failed (HTTP $STATUS)." >&2; exit 1 ;;
      esac
      if [ "$STATE" != INACTIVE ]; then
        send POST "$DOMAIN_URL/actions/deactivate" ''
        case "$STATUS" in
          200|202|204) echo "Deactivation of the identity domain struct8-cert-lab requested (HTTP $STATUS)." ;;
          *) cat "$OUT" >&2; echo "The identity domain struct8-cert-lab was not deactivated (HTTP $STATUS)." >&2; exit 1 ;;
        esac
      fi
      i=0
      while [ "$i" -lt 90 ]; do
        send GET "$DOMAIN_URL"
        state
        echo "Identity domain struct8-cert-lab: $STATE $DETAILS."
        if [ "$STATE" = INACTIVE ]; then exit 0; fi
        i=$((i + 1))
        sleep 10
      done
      echo "The identity domain struct8-cert-lab did not become inactive in 15 minutes." >&2
      exit 1
    EOT
  }
}

resource "oci_identity_domains_setting" "lab" {
  idcs_endpoint              = terraform_data.domain_guard.output
  schemas                    = ["urn:ietf:params:scim:schemas:oracle:idcs:Settings"]
  setting_id                 = "Settings"
  csr_access                 = "none"
  issuer                     = terraform_data.domain_guard.output
  signing_cert_public_access = true
}

resource "oci_identity_domains_oauth_client_certificate" "lab" {
  idcs_endpoint         = terraform_data.domain_guard.output
  schemas               = ["urn:ietf:params:scim:schemas:oracle:idcs:OAuthClientCertificate"]
  certificate_alias     = "struct8-cert-lab"
  x509base64certificate = local.certificate
}

resource "oci_identity_domains_app" "resource" {
  idcs_endpoint     = terraform_data.domain_guard.output
  schemas           = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]
  display_name      = "struct8-cert-lab-resource"
  description       = "Lab of the certificate assembled by Terraform."
  based_on_template {
    value = "CustomWebAppTemplateId"
  }
  is_oauth_resource = true
  audience          = local.audience
  scopes {
    value = "/"
  }
  active       = true
  force_delete = true
}

resource "terraform_data" "resource_deactivate" {
  triggers_replace = "${terraform_data.domain_guard.output}/admin/v1/AppStatusChanger/${oci_identity_domains_app.resource.id}"

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
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
        echo "No OCI credentials reach the machine that runs the destroy, and they deactivate the application struct8-cert-lab-resource before it is deleted." >&2
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
        200|204) echo "Application struct8-cert-lab-resource deactivated." ;;
        404) echo "Application struct8-cert-lab-resource no longer exists."; exit 0 ;;
        *) cat "$OUT" >&2; echo "The identity domain did not deactivate the application struct8-cert-lab-resource (HTTP $STATUS)." >&2; exit 1 ;;
      esac
    EOT
  }
}

resource "oci_identity_domains_app" "client" {
  idcs_endpoint     = terraform_data.domain_guard.output
  schemas           = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]
  display_name      = "struct8-cert-lab-client"
  description       = "Lab of the certificate assembled by Terraform."
  based_on_template {
    value = "CustomWebAppTemplateId"
  }
  is_oauth_client = true
  client_type     = "trusted"
  allowed_grants  = ["client_credentials"]
  allowed_scopes {
    fqs = "${oci_identity_domains_app.resource.audience}/"
  }
  certificates {
    cert_alias = oci_identity_domains_oauth_client_certificate.lab.certificate_alias
  }
  active       = true
  force_delete = true
}

resource "terraform_data" "client_deactivate" {
  triggers_replace = "${terraform_data.domain_guard.output}/admin/v1/AppStatusChanger/${oci_identity_domains_app.client.id}"

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
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
        echo "No OCI credentials reach the machine that runs the destroy, and they deactivate the application struct8-cert-lab-client before it is deleted." >&2
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
        200|204) echo "Application struct8-cert-lab-client deactivated." ;;
        404) echo "Application struct8-cert-lab-client no longer exists."; exit 0 ;;
        *) cat "$OUT" >&2; echo "The identity domain did not deactivate the application struct8-cert-lab-client (HTTP $STATUS)." >&2; exit 1 ;;
      esac
      send PATCH "$(printf '%s' "$APP_STATUS_URL" | sed -e 's|/AppStatusChanger/|/Apps/|')" '{"schemas":["urn:ietf:params:scim:api:messages:2.0:PatchOp"],"Operations":[{"op":"remove","path":"certificates"}]}'
      case "$STATUS" in
        200|204) echo "Certificates removed from the application struct8-cert-lab-client." ;;
        404) echo "Application struct8-cert-lab-client no longer exists." ;;
        *) cat "$OUT" >&2; echo "The identity domain did not remove the certificates from the application struct8-cert-lab-client (HTTP $STATUS)." >&2; exit 1 ;;
      esac
    EOT
  }
}

# ---- Probe: a client assertion signed by the same Vault key gets a token from the domain.

# x5t, the SHA-1 thumbprint of the certificate: HCL hashes only the UTF-8 form of a string, so
# the lab computes it on the runner. The product's function computes it itself.
data "external" "x5t" {
  program = ["python3", "-c", "import sys,json,base64,hashlib;d=json.load(sys.stdin);print(json.dumps({'x5t':base64.urlsafe_b64encode(hashlib.sha1(base64.b64decode(d['certificate'])).digest()).decode().rstrip('=')}))"]
  query   = { certificate = local.certificate }
}

resource "time_static" "assertion" {
  triggers = { client = oci_identity_domains_app.client.name }
}

locals {
  client_id = oci_identity_domains_app.client.name
  b64url    = { for k, v in {
    header = jsonencode({ alg = "RS256", typ = "JWT", x5t = data.external.x5t.result.x5t })
    claims = jsonencode({
      iss = local.client_id
      sub = local.client_id
      aud = ["https://identity.oraclecloud.com/", local.domain_url]
      iat = time_static.assertion.unix
      exp = time_static.assertion.unix + 300
      jti = "struct8-cert-lab-${time_static.assertion.unix}"
    })
  } : k => replace(replace(replace(base64encode(v), "+", "-"), "/", "_"), "=", "") }
  signing_input = "${local.b64url.header}.${local.b64url.claims}"
  assertion     = "${local.signing_input}.${replace(replace(replace(oci_kms_sign.assertion.signature, "+", "-"), "/", "_"), "=", "")}"
}

resource "oci_kms_sign" "assertion" {
  crypto_endpoint   = oci_kms_vault.lab.crypto_endpoint
  key_id            = oci_kms_key.lab.id
  key_version_id    = oci_kms_key.lab.current_key_version
  message           = base64encode(local.signing_input)
  message_type      = "RAW"
  signing_algorithm = "SHA_256_RSA_PKCS1_V1_5"
}

data "http" "token" {
  url    = "${local.domain_url}/oauth2/v1/token"
  method = "POST"
  request_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
    Accept         = "application/json"
  }
  request_body = join("&", [
    "grant_type=client_credentials",
    "scope=${urlencode("${oci_identity_domains_app.resource.audience}/")}",
    "client_id=${urlencode(local.client_id)}",
    "client_assertion_type=${urlencode("urn:ietf:params:oauth:client-assertion-type:jwt-bearer")}",
    "client_assertion=${local.assertion}",
  ])
  depends_on = [oci_identity_domains_setting.lab, terraform_data.client_deactivate, terraform_data.resource_deactivate]
}

# ---- Probe: what Google reads without a token, after the settings.
data "http" "discovery" {
  url        = "${local.domain_url}/.well-known/openid-configuration"
  depends_on = [oci_identity_domains_setting.lab]
}

locals {
  token_answer = try(jsondecode(data.http.token.response_body), {})
  access_token = try(local.token_answer.access_token, "")
  token_middle = try(split(".", local.access_token)[1], "")
  token_claims = local.token_middle == "" ? {} : jsondecode(base64decode(format("%s%s",
    replace(replace(local.token_middle, "-", "+"), "_", "/"),
  substr("===", 0, (4 - length(local.token_middle) % 4) % 4))))
  discovery = try(jsondecode(data.http.discovery.response_body), {})
}

data "http" "jwks" {
  url = try(local.discovery.jwks_uri, "${local.domain_url}/admin/v1/SigningCert/jwk")
}

output "certificate" {
  value = local.certificate
}

output "domain_url" {
  value = local.domain_url
}

output "token" {
  value = {
    status     = data.http.token.status_code
    token_type = try(local.token_answer.token_type, null)
    expires_in = try(local.token_answer.expires_in, null)
    error      = try(local.token_answer.error, null)
    error_text = try(local.token_answer.error_description, null)
    claims = { for k in ["iss", "aud", "sub", "client_id", "scope", "tok_type", "sub_type"] :
    k => try(local.token_claims[k], null) }
  }
}

output "discovery" {
  value = {
    status      = data.http.discovery.status_code
    issuer      = try(local.discovery.issuer, null)
    jwks_uri    = try(local.discovery.jwks_uri, null)
    jwks_status = data.http.jwks.status_code
    jwks_keys   = try(length(jsondecode(data.http.jwks.response_body).keys), null)
  }
}
