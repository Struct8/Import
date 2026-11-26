"""
Lab function: an OCI function writes, reads and lists objects in a Cloud
Storage bucket with no Google key, through a cldmn_workload_identity component
of a Google Cloud state.

Direction (10) of docs/cross-cloud-oci-matriz-plano.md in the CloudMan
repository. Temporary code: this branch of Struct8/Import is deleted when the
lab ends.

ACTIONS, as the body of the invoke:

  {"action": "certificate"}  the self-signed certificate of the Vault key of
                             the SIGNING connection, to type in the
                             component's oci_client_certificate_ field.
  {"action": "test"}         the whole chain, step by step (below). The
                             default when the body is empty.

THE CHAIN of "test":

  1. config     the variables the canvas wrote, by name.
  2. discovery  GET <domain>/.well-known/openid-configuration and the JWKS it
                names, without a token: Google reads both, and compares the
                issuer with the issuer_uri of the pool's provider.
  3. token      POST <domain>/oauth2/v1/token, grant client_credentials, scope
                <OIDC_AUDIENCE>/, authenticated by an RS256 client assertion
                the Vault signs (iss = sub = OCI_CLIENT_ID, header x5t).
  4. sts        POST https://sts.googleapis.com/v1/token, token exchange with
                audience //iam.googleapis.com/<GOOGLE_WORKLOAD_PROVIDER>: the
                federated token of the pool.
  5. tampered   the same exchange with one character of the token's signature
                changed: the STS must refuse it (invalid_grant).
  6. account    generateAccessToken of GOOGLE_SERVICE_ACCOUNT with the
                federated token (IAM Credentials).
  7. gcs        upload, download and list under oci-lab/ in the granted bucket
                (GOOGLE_STORAGE_BUCKET_NAME_<label of the connection>).
  8. control    upload to LAB_CONTROL_BUCKET, a bucket the service account
                has no grant on: Cloud Storage must refuse it (403).

The answer never carries a token or a credential: claims, HTTP status codes,
error codes and object names only.

The OCI request signature (resource principal 2.2), the Vault key, the
certificate and the domain token are those of the direction (9) lab
(lab/oci-aws-reader, deleted with its branch), which come from
backend/AgentOCI (oci_http.py, vault_key.py).
"""

import base64
import datetime
import email.utils
import hashlib
import json
import os
import re
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.x509.oid import NameOID

TIMEOUT_SECONDS = 10

ASSERTION_AUDIENCE = "https://identity.oraclecloud.com/"
ASSERTION_SECONDS = 300
SCOPE_VALUE = "/"
DOMAIN_URL = re.compile(r"^https://idcs-[0-9a-f]+\.identity\.oraclecloud\.com$")

GOOGLE_STS_URL = "https://sts.googleapis.com/v1/token"
IAM_CREDENTIALS_URL = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/{}:generateAccessToken"
GCS_URL = "https://storage.googleapis.com"
CLOUD_PLATFORM = "https://www.googleapis.com/auth/cloud-platform"
ACCESS_TOKEN_LIFETIME = "900s"

PREFIX = "oci-lab/"
BUCKET_VARIABLE_PREFIX = "GOOGLE_STORAGE_BUCKET_NAME_"
PREFERRED_BUCKET_LABEL = "LAB"
CONTROL_BUCKET_VARIABLE = "LAB_CONTROL_BUCKET"

KMS_API_VERSION = "20180608"
SIGNING_ALGORITHM = "SHA_256_RSA_PKCS1_V1_5"
CERTIFICATE_SUBJECT = "Struct8 OCI lab"
CERTIFICATE_DAYS = 3650
# AlgorithmIdentifier of sha256WithRSAEncryption (1.2.840.113549.1.1.11), NULL parameters.
_SHA256_WITH_RSA = bytes.fromhex("300d06092a864886f70d01010b0500")

OCI_GENERIC_HEADERS = ("date", "(request-target)", "host")
OCI_BODY_HEADERS = ("content-length", "content-type", "x-content-sha256")

# Claims of the access token worth reporting; the token itself never leaves.
TOKEN_CLAIMS = ("iss", "aud", "sub", "client_id", "client_name", "scope", "tok_type", "sub_type", "iat", "exp")


class LabError(Exception):
    def __init__(self, code, detail=""):
        super().__init__(f"{code}: {detail}" if detail else code)
        self.code = code
        self.detail = detail


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def jwt_part(token, index):
    """One decoded JSON part of a compact JWT (0 = header, 1 = claims), or {}."""
    try:
        part = token.split(".")[index]
        return json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))
    except (IndexError, ValueError, AttributeError):
        return {}


def tampered(token):
    """The token with one character in the middle of its signature changed."""
    head, claims, signature = token.split(".")
    i = len(signature) // 2
    swapped = "A" if signature[i] != "A" else "B"
    return f"{head}.{claims}.{signature[:i]}{swapped}{signature[i + 1:]}"


def normalize_domain_url(value):
    url = (value or "").strip().rstrip("/").replace(":443", "")
    return url if DOMAIN_URL.match(url) else None


# HTTP -------------------------------------------------------------------------


class Http:
    """(status, headers with lower-case names, body) of one request; an HTTP error is an answer too."""

    def __init__(self, opener=None):
        self._open = opener or urllib.request.urlopen

    def __call__(self, method, url, body=None, headers=None):
        request = urllib.request.Request(url, data=body, method=method, headers=headers or {})
        try:
            with self._open(request, timeout=TIMEOUT_SECONDS) as response:
                return response.status, {k.lower(): v for k, v in response.headers.items()}, response.read()
        except urllib.error.HTTPError as e:
            return e.code, {k.lower(): v for k, v in (e.headers or {}).items()}, e.read()
        except (urllib.error.URLError, OSError) as e:
            raise LabError("unreachable", f"{urllib.parse.urlsplit(url).netloc}: {getattr(e, 'reason', e)}") from e


# OCI request signature, with the function's resource principal ----------------


def _value_or_file(value):
    if value and os.path.isabs(value):
        with open(value) as f:
            return f.read().strip()
    return value


class ResourcePrincipal:
    def __init__(self, environ=os.environ):
        self._environ = environ
        self._lock = threading.Lock()
        self._key_pem = None
        self._key = None

    def _require(self):
        e = self._environ
        if not (e.get("OCI_RESOURCE_PRINCIPAL_RPST") and e.get("OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM")):
            raise LabError("resource_principal_missing")
        if e.get("OCI_RESOURCE_PRINCIPAL_VERSION", "") != "2.2":
            raise LabError("resource_principal_version", e.get("OCI_RESOURCE_PRINCIPAL_VERSION", "missing"))

    def session_token(self):
        self._require()
        return _value_or_file(self._environ["OCI_RESOURCE_PRINCIPAL_RPST"])

    def private_key(self):
        self._require()
        pem = _value_or_file(self._environ["OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM"])
        with self._lock:
            if pem != self._key_pem:
                passphrase = _value_or_file(self._environ.get("OCI_RESOURCE_PRINCIPAL_PRIVATE_PEM_PASSPHRASE", ""))
                self._key = serialization.load_pem_private_key(
                    pem.encode(), password=passphrase.encode() if passphrase else None)
                self._key_pem = pem
            return self._key


def oci_signing_headers(method, url, body, key_id, private_key, date=None):
    parts = urllib.parse.urlsplit(url)
    target = parts.path + (f"?{parts.query}" if parts.query else "")
    headers = {"date": date or email.utils.formatdate(usegmt=True), "host": parts.netloc}
    names = list(OCI_GENERIC_HEADERS)
    if body is not None:
        headers["content-length"] = str(len(body))
        headers["content-type"] = "application/json"
        headers["x-content-sha256"] = base64.b64encode(hashlib.sha256(body).digest()).decode()
        names += OCI_BODY_HEADERS

    def line(name):
        if name == "(request-target)":
            return f"(request-target): {method.lower()} {target}"
        return f"{name}: {headers[name]}"

    signature = private_key.sign("\n".join(line(n) for n in names).encode(), padding.PKCS1v15(), hashes.SHA256())
    headers["authorization"] = (
        f'Signature version="1",keyId="{key_id}",algorithm="rsa-sha256",'
        f'headers="{" ".join(names)}",signature="{base64.b64encode(signature).decode()}"'
    )
    return headers


class OciClient:
    def __init__(self, principal=None, http=None):
        self.principal = principal or ResourcePrincipal()
        self.http = http or Http()

    def call(self, method, url, payload=None):
        body = None if payload is None else json.dumps(payload, separators=(",", ":")).encode()
        headers = oci_signing_headers(method, url, body, f"ST${self.principal.session_token()}",
                                      self.principal.private_key())
        headers["accept"] = "application/json"
        status, _, raw = self.http(method, url, body, headers)
        if not 200 <= status < 300:
            try:
                detail = json.loads(raw or b"{}")
            except ValueError:
                detail = {}
            raise LabError("oci_api_error", f"{status} {detail.get('code', '')}: "
                                            f"{detail.get('message', raw[:300].decode('utf-8', 'replace'))}")
        return json.loads(raw) if raw else {}


# The Vault key and its certificate (backend/AgentOCI/agent_oci/vault_key.py) --


def _der_length(n):
    if n < 0x80:
        return bytes([n])
    raw = n.to_bytes((n.bit_length() + 7) // 8, "big")
    return bytes([0x80 | len(raw)]) + raw


def _der(tag, content):
    return bytes([tag]) + _der_length(len(content)) + content


def _parse_time(text):
    value = datetime.datetime.fromisoformat(re.sub(r"\.\d+", "", text).replace("Z", "+00:00"))
    if value.tzinfo is None:
        value = value.replace(tzinfo=datetime.timezone.utc)
    return value.astimezone(datetime.timezone.utc).replace(microsecond=0)


def _endpoint(value):
    value = (value or "").rstrip("/")
    if value and not value.startswith("https://"):
        value = f"https://{value}"
    return value


class VaultKey:
    def __init__(self, client, key_id, crypto_endpoint, management_endpoint):
        self.client = client
        self.key_id = key_id
        self.crypto_endpoint = _endpoint(crypto_endpoint)
        self.management_endpoint = _endpoint(management_endpoint)
        self._lock = threading.Lock()
        self._version = None
        self._certificate = None

    @classmethod
    def from_environment(cls, client, environ):
        key_id = environ.get("OCI_KMS_KEY_ID_SIGNING", "")
        if not key_id:
            raise LabError("signing_key_missing", "No connection labelled SIGNING to an oci_kms_key.")
        return cls(client, key_id, environ.get("OCI_KMS_KEY_CRYPTO_ENDPOINT_SIGNING", ""),
                   environ.get("OCI_KMS_KEY_MANAGEMENT_ENDPOINT_SIGNING", ""))

    def current_version(self):
        with self._lock:
            if self._version is None:
                if not (self.crypto_endpoint and self.management_endpoint):
                    raise LabError("signing_key_endpoints_missing")
                key_path = (f"{self.management_endpoint}/{KMS_API_VERSION}/keys/"
                            f"{urllib.parse.quote(self.key_id, safe='')}")
                version_id = self.client.call("GET", key_path).get("currentKeyVersion")
                if not version_id:
                    raise LabError("signing_key_no_version")
                version = self.client.call("GET", f"{key_path}/keyVersions/{urllib.parse.quote(version_id, safe='')}")
                public_key = serialization.load_pem_public_key(version["publicKey"].encode())
                if not isinstance(public_key, rsa.RSAPublicKey):
                    raise LabError("signing_key_not_rsa")
                self._version = {"id": version_id, "public_key": public_key,
                                 "time_created": _parse_time(version["timeCreated"])}
            return self._version

    def sign(self, data):
        version = self.current_version()
        answer = self.client.call("POST", f"{self.crypto_endpoint}/{KMS_API_VERSION}/sign", {
            "keyId": self.key_id,
            "keyVersionId": version["id"],
            "message": base64.b64encode(hashlib.sha256(data).digest()).decode(),
            "messageType": "DIGEST",
            "signingAlgorithm": SIGNING_ALGORITHM,
        })
        signature = base64.b64decode(answer.get("signature", ""))
        try:
            version["public_key"].verify(signature, data, padding.PKCS1v15(), hashes.SHA256())
        except Exception as e:
            raise LabError("signing_key_signature_mismatch") from e
        return signature

    def certificate(self):
        with self._lock:
            if self._certificate is not None:
                return self._certificate
        version = self.current_version()
        name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, CERTIFICATE_SUBJECT)])
        start = version["time_created"]
        serial = int.from_bytes(hashlib.sha256(version["id"].encode()).digest()[:16], "big") >> 1
        builder = (
            x509.CertificateBuilder()
            .subject_name(name)
            .issuer_name(name)
            .public_key(version["public_key"])
            .serial_number(serial)
            .not_valid_before(start)
            .not_valid_after(start + datetime.timedelta(days=CERTIFICATE_DAYS))
            .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
            .add_extension(x509.KeyUsage(
                digital_signature=True, content_commitment=False, key_encipherment=False,
                data_encipherment=False, key_agreement=False, key_cert_sign=False, crl_sign=False,
                encipher_only=False, decipher_only=False), critical=True)
            .add_extension(x509.SubjectKeyIdentifier.from_public_key(version["public_key"]), critical=False)
        )
        # Signed first by a throwaway key, which fixes the signature algorithm in the
        # to-be-signed part and nothing else; that part is then signed by the Vault.
        throwaway = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        tbs = builder.sign(throwaway, hashes.SHA256()).tbs_certificate_bytes
        der = _der(0x30, tbs + _SHA256_WITH_RSA + _der(0x03, b"\x00" + self.sign(tbs)))
        x509.load_der_x509_certificate(der)
        with self._lock:
            self._certificate = der
        return der

    def certificate_pem(self):
        body = base64.encodebytes(self.certificate()).decode().replace("\n", "")
        return ("-----BEGIN CERTIFICATE-----\n" + "\n".join(body[i:i + 64] for i in range(0, len(body), 64)) +
                "\n-----END CERTIFICATE-----\n")

    def x5t(self):
        return b64url(hashlib.sha1(self.certificate()).digest())

    def sign_jwt(self, claims, header=None):
        full_header = {"alg": "RS256", "typ": "JWT", "x5t": self.x5t(), **(header or {})}
        signing_input = (b64url(json.dumps(full_header, separators=(",", ":")).encode()) + "." +
                         b64url(json.dumps(claims, separators=(",", ":")).encode()))
        return signing_input + "." + b64url(self.sign(signing_input.encode()))


# Google: STS, IAM Credentials and Cloud Storage ---------------------------------


def google_error(raw):
    """(code, message) of a Google error body: the STS form ({"error", "error_description"})
    or the JSON API form ({"error": {"code", "status", "message"}})."""
    try:
        body = json.loads(raw or b"{}")
    except ValueError:
        return "unreadable", (raw or b"")[:300].decode("utf-8", "replace")
    error = body.get("error") if isinstance(body, dict) else None
    if isinstance(error, dict):
        return error.get("status") or str(error.get("code") or "unknown"), str(error.get("message", ""))[:300]
    return error or "unknown", str(body.get("error_description", "") if isinstance(body, dict) else "")[:300]


def provider_name(value):
    """The provider's resource name, without the //iam.googleapis.com/ prefix if it was typed."""
    value = (value or "").strip()
    prefix = "//iam.googleapis.com/"
    return value[len(prefix):] if value.startswith(prefix) else value


def exchange_token(http, provider, subject_token):
    """(report, federated access token or None) of the STS token exchange."""
    audience = f"//iam.googleapis.com/{provider_name(provider)}"
    form = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
        "audience": audience,
        "scope": CLOUD_PLATFORM,
        "requested_token_type": "urn:ietf:params:oauth:token-type:access_token",
        "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
        "subject_token": subject_token,
    }).encode()
    status, _, raw = http("POST", GOOGLE_STS_URL, form,
                          {"content-type": "application/x-www-form-urlencoded", "accept": "application/json"})
    report = {"status": status, "audience": audience}
    if status == 200:
        answer = json.loads(raw)
        report.update(issuedTokenType=answer.get("issued_token_type"), tokenType=answer.get("token_type"),
                      expiresIn=answer.get("expires_in"))
        return report, answer.get("access_token")
    report["code"], report["message"] = google_error(raw)
    return report, None


def service_account_token(http, account, federated_token):
    """(report, access token of the service account or None): generateAccessToken."""
    url = IAM_CREDENTIALS_URL.format(urllib.parse.quote(account, safe="@."))
    body = json.dumps({"scope": [CLOUD_PLATFORM], "lifetime": ACCESS_TOKEN_LIFETIME}).encode()
    status, _, raw = http("POST", url, body, {"authorization": f"Bearer {federated_token}",
                                              "content-type": "application/json", "accept": "application/json"})
    report = {"status": status, "serviceAccount": account}
    if status == 200:
        answer = json.loads(raw)
        report["expireTime"] = answer.get("expireTime")
        return report, answer.get("accessToken")
    report["code"], report["message"] = google_error(raw)
    return report, None


class Gcs:
    """Cloud Storage JSON API with a bearer token; each call is (status, headers, body)."""

    def __init__(self, http, token):
        self.http = http
        self._token = token

    def _headers(self, extra=None):
        return {"authorization": f"Bearer {self._token}", **(extra or {})}

    @staticmethod
    def _q(value):
        return urllib.parse.quote(value, safe="")

    def upload(self, bucket, name, body, content_type):
        url = f"{GCS_URL}/upload/storage/v1/b/{self._q(bucket)}/o?uploadType=media&name={self._q(name)}"
        return self.http("POST", url, body, self._headers({"content-type": content_type,
                                                           "accept": "application/json"}))

    def download(self, bucket, name):
        return self.http("GET", f"{GCS_URL}/storage/v1/b/{self._q(bucket)}/o/{self._q(name)}?alt=media",
                         None, self._headers())

    def list(self, bucket, prefix):
        return self.http("GET", f"{GCS_URL}/storage/v1/b/{self._q(bucket)}/o?prefix={self._q(prefix)}",
                         None, self._headers({"accept": "application/json"}))


# The lab ------------------------------------------------------------------------


def granted_bucket(environ):
    """(variable, bucket) of the granted bucket: the one labelled LAB, or the only one."""
    preferred = BUCKET_VARIABLE_PREFIX + PREFERRED_BUCKET_LABEL
    if environ.get(preferred):
        return preferred, environ[preferred]
    found = sorted(k for k in environ if k.startswith(BUCKET_VARIABLE_PREFIX) and environ[k])
    if len(found) == 1:
        return found[0], environ[found[0]]
    return None, None


REQUIRED = ("OCI_IDENTITY_DOMAIN_URL", "OCI_CLIENT_ID", "OIDC_AUDIENCE", "GOOGLE_WORKLOAD_PROVIDER",
            "GOOGLE_SERVICE_ACCOUNT", "OCI_KMS_KEY_ID_SIGNING", "OCI_KMS_KEY_CRYPTO_ENDPOINT_SIGNING",
            "OCI_KMS_KEY_MANAGEMENT_ENDPOINT_SIGNING", CONTROL_BUCKET_VARIABLE)

STEP_COUNT = 8


def step_config(environ):
    missing = [name for name in REQUIRED if not environ.get(name)]
    variable, bucket = granted_bucket(environ)
    if not variable:
        missing.append(BUCKET_VARIABLE_PREFIX + "<label>")
    domain = normalize_domain_url(environ.get("OCI_IDENTITY_DOMAIN_URL"))
    return {
        "ok": not missing and domain is not None,
        "missing": missing,
        "domain": environ.get("OCI_IDENTITY_DOMAIN_URL"),
        "domainValid": domain is not None,
        "clientId": environ.get("OCI_CLIENT_ID"),
        "certificateAlias": environ.get("OCI_CERTIFICATE_ALIAS"),
        "audience": environ.get("OIDC_AUDIENCE"),
        "provider": environ.get("GOOGLE_WORKLOAD_PROVIDER"),
        "serviceAccount": environ.get("GOOGLE_SERVICE_ACCOUNT"),
        "bucketVariable": variable,
        "bucket": bucket,
        "controlBucket": environ.get(CONTROL_BUCKET_VARIABLE),
        "googleVariables": sorted(k for k in environ if k.startswith("GOOGLE_")),
    }


def step_discovery(http, domain):
    status, _, raw = http("GET", f"{domain}/.well-known/openid-configuration", None, {"accept": "application/json"})
    report = {"status": status}
    if status != 200:
        report.update(ok=False, body=raw[:300].decode("utf-8", "replace"))
        return report
    document = json.loads(raw)
    report["issuer"] = document.get("issuer")
    report["jwksUri"] = document.get("jwks_uri")
    report["issuerIsDomain"] = (document.get("issuer") or "").rstrip("/") == domain
    jwks_status, _, jwks_raw = http("GET", document.get("jwks_uri") or "", None, {"accept": "application/json"})
    report["jwksStatus"] = jwks_status
    keys = json.loads(jwks_raw).get("keys", []) if jwks_status == 200 else []
    report["jwksKeys"] = [{"kid": k.get("kid"), "kty": k.get("kty"), "x5t": k.get("x5t")} for k in keys]
    report["ok"] = report["issuerIsDomain"] and jwks_status == 200 and len(keys) > 0
    return report


def request_token(http, key, domain, client_id, audience, kid=None, clock=time.time):
    now = int(clock())
    assertion = key.sign_jwt({
        "iss": client_id, "sub": client_id, "aud": [ASSERTION_AUDIENCE, domain],
        "iat": now, "nbf": now - 30, "exp": now + ASSERTION_SECONDS, "jti": str(uuid.uuid4()),
    }, header={"kid": kid} if kid else None)
    form = urllib.parse.urlencode({
        "grant_type": "client_credentials",
        "scope": f"{audience}{SCOPE_VALUE}",
        "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion": assertion,
        "client_id": client_id,
    }).encode()
    status, _, raw = http("POST", f"{domain}/oauth2/v1/token", form,
                          {"content-type": "application/x-www-form-urlencoded", "accept": "application/json"})
    try:
        answer = json.loads(raw or b"{}")
    except ValueError:
        answer = {}
    return status, answer


def step_token(http, key, environ, domain, clock=time.time):
    """(report, access token or None). With x5t only first; with kid too if the domain refuses."""
    client_id = environ["OCI_CLIENT_ID"]
    audience = environ["OIDC_AUDIENCE"]
    attempts = []
    token = None
    for kid in (None, environ.get("OCI_CERTIFICATE_ALIAS")):
        if attempts and not kid:
            break
        status, answer = request_token(http, key, domain, client_id, audience, kid, clock)
        attempt = {"header": "x5t+kid" if kid else "x5t", "status": status}
        if status == 200 and answer.get("access_token"):
            token = answer["access_token"]
            attempt.update(tokenType=answer.get("token_type"), expiresIn=answer.get("expires_in"))
            attempts.append(attempt)
            break
        attempt.update(error=answer.get("error"), description=str(answer.get("error_description", ""))[:300])
        attempts.append(attempt)
    report = {"ok": token is not None, "scope": f"{audience}{SCOPE_VALUE}", "attempts": attempts}
    if token:
        claims = jwt_part(token, 1)
        header = jwt_part(token, 0)
        report["header"] = {k: header.get(k) for k in ("alg", "kid", "x5t") if k in header}
        report["claims"] = {k: claims[k] for k in TOKEN_CLAIMS if k in claims}
        aud = claims.get("aud")
        report["audienceMatches"] = audience in (aud if isinstance(aud, list) else [aud])
        report["issuerIsDomain"] = (claims.get("iss") or "").rstrip("/") == domain
    return report, token


def step_gcs(gcs, bucket, function_id, clock=time.time):
    stamp = datetime.datetime.fromtimestamp(clock(), datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    name = f"{PREFIX}{stamp}-{uuid.uuid4().hex[:8]}.json"
    body = json.dumps({"writtenBy": "OCI function through cldmn_workload_identity",
                       "function": function_id, "at": stamp}, indent=1).encode()
    report = {"bucket": bucket, "object": name}

    status, _, raw = gcs.upload(bucket, name, body, "application/json")
    report["upload"] = {"status": status}
    if status != 200:
        report["upload"]["code"], report["upload"]["message"] = google_error(raw)
        report["ok"] = False
        return report

    status, _, raw = gcs.download(bucket, name)
    report["download"] = {"status": status, "sameBytes": status == 200 and raw == body}
    if status != 200:
        report["download"]["code"], report["download"]["message"] = google_error(raw)

    status, _, raw = gcs.list(bucket, PREFIX)
    listing = {"status": status}
    if status == 200:
        names = [item.get("name") for item in json.loads(raw).get("items", [])]
        listing.update(count=len(names), containsObject=name in names)
    else:
        listing["code"], listing["message"] = google_error(raw)
    report["list"] = listing
    report["ok"] = report["download"]["sameBytes"] and listing.get("containsObject") is True
    return report


def step_control(gcs, bucket):
    status, _, raw = gcs.upload(bucket, f"{PREFIX}must-be-refused.txt", b"refused", "text/plain")
    code, message = google_error(raw) if status != 200 else ("", "")
    return {"ok": status == 403, "bucket": bucket, "status": status, "code": code, "message": message}


def run_test(environ, http, oci_client, clock=time.time):
    steps = {}
    started = time.monotonic()

    def finish():
        return {"action": "test", "passed": all(s.get("ok") for s in steps.values()) and len(steps) == STEP_COUNT,
                "seconds": round(time.monotonic() - started, 2), "steps": steps}

    def guarded(name, fn):
        try:
            return fn()
        except LabError as e:
            steps[name] = {"ok": False, "error": e.code, "detail": e.detail}
        except Exception as e:  # report, never raise: the answer is the measurement
            steps[name] = {"ok": False, "error": type(e).__name__, "detail": str(e)[:300]}
        return None

    steps["config"] = step_config(environ)
    if not steps["config"]["ok"]:
        return finish()
    domain = normalize_domain_url(environ["OCI_IDENTITY_DOMAIN_URL"])
    provider = environ["GOOGLE_WORKLOAD_PROVIDER"]

    discovery = guarded("discovery", lambda: step_discovery(http, domain))
    if discovery is not None:
        steps["discovery"] = discovery

    key = VaultKey.from_environment(oci_client, environ)
    result = guarded("token", lambda: step_token(http, key, environ, domain, clock))
    if result is None:
        return finish()
    steps["token"], token = result
    if token is None:
        return finish()

    result = guarded("sts", lambda: exchange_token(http, provider, token))
    if result is None:
        return finish()
    report, federated = result
    report["ok"] = federated is not None
    steps["sts"] = report

    result = guarded("tampered", lambda: exchange_token(http, provider, tampered(token)))
    if result is not None:
        report, refused = result
        report["ok"] = refused is None and report.get("code") == "invalid_grant"
        steps["tampered"] = report

    if federated is None:
        return finish()
    result = guarded("account", lambda: service_account_token(http, environ["GOOGLE_SERVICE_ACCOUNT"], federated))
    if result is None:
        return finish()
    report, access_token = result
    report["ok"] = access_token is not None
    steps["account"] = report
    if access_token is None:
        return finish()

    gcs = Gcs(http, access_token)
    _, bucket = granted_bucket(environ)
    function_id = environ.get("FN_FN_ID", "")
    result = guarded("gcs", lambda: step_gcs(gcs, bucket, function_id, clock))
    if result is not None:
        steps["gcs"] = result
    result = guarded("control", lambda: step_control(gcs, environ[CONTROL_BUCKET_VARIABLE]))
    if result is not None:
        steps["control"] = result
    return finish()


def run_certificate(environ, oci_client):
    key = VaultKey.from_environment(oci_client, environ)
    version = key.current_version()
    return {
        "action": "certificate",
        "keyVersionId": version["id"],
        "x5t": key.x5t(),
        "notBefore": version["time_created"].isoformat(),
        "notAfter": (version["time_created"] + datetime.timedelta(days=CERTIFICATE_DAYS)).isoformat(),
        "certificatePem": key.certificate_pem(),
    }


def handle(raw, environ=None, http=None, oci_client=None):
    environ = os.environ if environ is None else environ
    http = http or Http()
    try:
        request = json.loads(raw or b"{}")
    except ValueError:
        return {"error": "body_not_json"}
    action = (request.get("action") if isinstance(request, dict) else None) or "test"
    try:
        client = oci_client or OciClient(ResourcePrincipal(environ), http)
        if action == "certificate":
            return run_certificate(environ, client)
        if action == "test":
            return run_test(environ, http, client)
        return {"error": "unknown_action", "action": action}
    except LabError as e:
        return {"action": action, "error": e.code, "detail": e.detail}
