"""
Tests of lab_caller.py, with the standard library and cryptography only:
python -m unittest test_lab_caller

The chain runs against fakes of the Vault, the identity domain, Google STS,
IAM Credentials and Cloud Storage. The request shapes follow the Google
documentation of the token exchange (sts.googleapis.com/v1/token),
generateAccessToken and the Cloud Storage JSON API.
"""

import base64
import hashlib
import json
import unittest
import urllib.parse

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa, utils

import lab_caller as lab



class FakeVault:
    """GetKey, GetKeyVersion and Sign of a Vault holding one RSA key."""

    VERSION = "ocid1.keyversion.oc1.sa-saopaulo-1.lab"

    def __init__(self):
        self.private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        self.public_key = self.private_key.public_key()
        self.calls = []

    def call(self, method, url, payload=None):
        self.calls.append((method, url))
        if method == "GET" and "/keyVersions/" in url:
            pem = self.public_key.public_bytes(serialization.Encoding.PEM,
                                               serialization.PublicFormat.SubjectPublicKeyInfo).decode()
            return {"publicKey": pem, "timeCreated": "2026-11-26T10:00:00.123Z"}
        if method == "GET" and "/keys/" in url:
            return {"currentKeyVersion": self.VERSION}
        if method == "POST" and url.endswith("/20180608/sign"):
            assert payload["messageType"] == "DIGEST" and payload["keyVersionId"] == self.VERSION
            digest = base64.b64decode(payload["message"])
            signature = self.private_key.sign(digest, padding.PKCS1v15(), utils.Prehashed(hashes.SHA256()))
            return {"signature": base64.b64encode(signature).decode()}
        raise AssertionError(f"unexpected Vault call {method} {url}")


ENV = {
    "OCI_KMS_KEY_ID_SIGNING": "ocid1.key.oc1.sa-saopaulo-1.lab",
    "OCI_KMS_KEY_CRYPTO_ENDPOINT_SIGNING": "https://lab-crypto.kms.sa-saopaulo-1.oraclecloud.com",
    "OCI_KMS_KEY_MANAGEMENT_ENDPOINT_SIGNING": "https://lab-management.kms.sa-saopaulo-1.oraclecloud.com",
}


class VaultCertificate(unittest.TestCase):
    def setUp(self):
        self.vault = FakeVault()
        self.key = lab.VaultKey.from_environment(self.vault, ENV)

    def test_certificate_is_signed_by_the_vault_key(self):
        certificate = x509.load_der_x509_certificate(self.key.certificate())
        self.vault.public_key.verify(certificate.signature, certificate.tbs_certificate_bytes,
                                     padding.PKCS1v15(), hashes.SHA256())
        self.assertEqual(certificate.public_key().public_numbers(), self.vault.public_key.public_numbers())

    def test_jwt_names_the_certificate_and_verifies(self):
        token = self.key.sign_jwt({"sub": "x"})
        head, claims, signature = token.split(".")
        header = lab.jwt_part(token, 0)
        self.assertEqual(header["x5t"], lab.b64url(hashlib.sha1(self.key.certificate()).digest()))
        raw = base64.urlsafe_b64decode(signature + "=" * (-len(signature) % 4))
        self.vault.public_key.verify(raw, f"{head}.{claims}".encode(), padding.PKCS1v15(), hashes.SHA256())

    def test_certificate_action(self):
        answer = lab.handle(b'{"action":"certificate"}', environ=ENV, http=object(), oci_client=self.vault)
        self.assertEqual(answer["keyVersionId"], FakeVault.VERSION)
        self.assertTrue(answer["certificatePem"].startswith("-----BEGIN CERTIFICATE-----\n"))
        x509.load_pem_x509_certificate(answer["certificatePem"].encode())
        self.assertEqual(answer["notBefore"], "2026-11-26T10:00:00+00:00")



DOMAIN = "https://idcs-0123456789abcdef0123456789abcdef.identity.oraclecloud.com"
AUDIENCE = "sts.googleapis.com/oci-lab-reader"
PROVIDER = "projects/123456789012/locations/global/workloadIdentityPools/oci-lab-reader/providers/oci-domain"
ACCOUNT = "oci-lab-reader@lab-project.iam.gserviceaccount.com"
TEST_ENV = {
    **ENV,
    "OCI_IDENTITY_DOMAIN_URL": DOMAIN + "/",
    "OCI_CLIENT_ID": "0a1b2c3d4e5f",
    "OCI_CERTIFICATE_ALIAS": "oci-lab-reader-client",
    "OIDC_AUDIENCE": AUDIENCE,
    "GOOGLE_WORKLOAD_PROVIDER": PROVIDER,
    "GOOGLE_SERVICE_ACCOUNT": ACCOUNT,
    "GOOGLE_STORAGE_BUCKET_NAME_LAB": "oci-lab-granted",
    "GOOGLE_STORAGE_BUCKET_ACCOUNT_LAB": "lab-project",
    "LAB_CONTROL_BUCKET": "oci-lab-control",
}
FEDERATED = "federated-token-of-the-pool"
ACCESS = "access-token-of-the-service-account"


def unsigned_jwt(claims):
    return ".".join([lab.b64url(json.dumps({"alg": "RS256", "kid": "SIGNING_KEY"}).encode()),
                     lab.b64url(json.dumps(claims).encode()), lab.b64url(b"s" * 256)])


class FakeClouds:
    """The identity domain, Google STS, IAM Credentials and Cloud Storage, as the chain sees them."""

    def __init__(self, vault, issuer=DOMAIN, refuse_x5t_only=False, account_denied=False):
        self.vault = vault
        self.issuer = issuer
        self.refuse_x5t_only = refuse_x5t_only
        self.account_denied = account_denied
        self.access_token = unsigned_jwt({"iss": issuer, "aud": AUDIENCE, "sub": "0a1b2c3d4e5f",
                                          "client_id": "0a1b2c3d4e5f", "scope": "/", "exp": 2000000000})
        self.objects = {}
        self.requests = []

    def __call__(self, method, url, body=None, headers=None):
        self.requests.append((method, url, headers or {}))
        parts = urllib.parse.urlsplit(url)
        if url == f"{DOMAIN}/.well-known/openid-configuration":
            return 200, {}, json.dumps({"issuer": self.issuer, "jwks_uri": f"{DOMAIN}/admin/v1/SigningCert/jwk"}).encode()
        if url == f"{DOMAIN}/admin/v1/SigningCert/jwk":
            return 200, {}, json.dumps({"keys": [{"kid": "SIGNING_KEY", "kty": "RSA", "x5t": "abc"}]}).encode()
        if url == f"{DOMAIN}/oauth2/v1/token":
            return self._token(dict(urllib.parse.parse_qsl(body.decode())))
        if url == "https://sts.googleapis.com/v1/token":
            return self._sts(dict(urllib.parse.parse_qsl(body.decode())))
        if parts.netloc == "iamcredentials.googleapis.com":
            return self._account(parts, body, headers)
        if parts.netloc == "storage.googleapis.com":
            return self._gcs(method, parts, body, headers)
        raise AssertionError(f"unexpected request {method} {url}")

    def _token(self, form):
        assert form["grant_type"] == "client_credentials"
        assert form["scope"] == AUDIENCE + "/"
        assertion = form["client_assertion"]
        head, claims, signature = assertion.split(".")
        raw = base64.urlsafe_b64decode(signature + "=" * (-len(signature) % 4))
        self.vault.public_key.verify(raw, f"{head}.{claims}".encode(), padding.PKCS1v15(), hashes.SHA256())
        payload = lab.jwt_part(assertion, 1)
        assert payload["iss"] == payload["sub"] == form["client_id"] == "0a1b2c3d4e5f"
        assert payload["aud"] == ["https://identity.oraclecloud.com/", DOMAIN]
        if self.refuse_x5t_only and "kid" not in lab.jwt_part(assertion, 0):
            return 401, {}, json.dumps({"error": "invalid_client", "error_description": "no kid"}).encode()
        return 200, {}, json.dumps({"access_token": self.access_token, "token_type": "Bearer",
                                    "expires_in": 3600}).encode()

    def _sts(self, form):
        assert form["grant_type"] == "urn:ietf:params:oauth:grant-type:token-exchange"
        assert form["audience"] == f"//iam.googleapis.com/{PROVIDER}"
        assert form["subject_token_type"] == "urn:ietf:params:oauth:token-type:jwt"
        assert form["requested_token_type"] == "urn:ietf:params:oauth:token-type:access_token"
        assert form["scope"] == "https://www.googleapis.com/auth/cloud-platform"
        if form["subject_token"] != self.access_token:
            return 400, {}, json.dumps({"error": "invalid_grant",
                                        "error_description": "Invalid JWT signature."}).encode()
        return 200, {}, json.dumps({"access_token": FEDERATED, "issued_token_type":
                                    "urn:ietf:params:oauth:token-type:access_token",
                                    "token_type": "Bearer", "expires_in": 3599}).encode()

    def _account(self, parts, body, headers):
        assert parts.path == f"/v1/projects/-/serviceAccounts/{ACCOUNT}:generateAccessToken"
        assert headers["authorization"] == f"Bearer {FEDERATED}"
        assert json.loads(body) == {"scope": ["https://www.googleapis.com/auth/cloud-platform"], "lifetime": "900s"}
        if self.account_denied:
            return 403, {}, json.dumps({"error": {"code": 403, "status": "PERMISSION_DENIED", "message":
                                                  "Permission 'iam.serviceAccounts.getAccessToken' denied"}}).encode()
        return 200, {}, json.dumps({"accessToken": ACCESS, "expireTime": "2026-11-26T12:15:00Z"}).encode()

    def _gcs(self, method, parts, body, headers):
        assert headers["authorization"] == f"Bearer {ACCESS}"
        query = dict(urllib.parse.parse_qsl(parts.query))
        if parts.path.startswith("/upload/storage/v1/b/"):
            bucket = urllib.parse.unquote(parts.path.split("/")[5])
            assert method == "POST" and query["uploadType"] == "media"
            if bucket == "oci-lab-control":
                return 403, {}, json.dumps({"error": {"code": 403, "message": f"{ACCOUNT} does not have "
                                                      "storage.objects.create access"}}).encode()
            assert bucket == "oci-lab-granted"
            self.objects[query["name"]] = body
            return 200, {}, json.dumps({"name": query["name"], "bucket": bucket}).encode()
        segments = parts.path.split("/")
        assert segments[1:5] == ["storage", "v1", "b", "oci-lab-granted"] and method == "GET"
        if len(segments) == 7:
            assert query == {"alt": "media"}
            return 200, {}, self.objects[urllib.parse.unquote(segments[6])]
        assert query == {"prefix": "oci-lab/"}
        return 200, {}, json.dumps({"items": [{"name": n} for n in self.objects]}).encode()


class TheChain(unittest.TestCase):
    def run_chain(self, **options):
        vault = FakeVault()
        clouds = FakeClouds(vault, **options)
        answer = lab.handle(b'{"action":"test"}', environ=TEST_ENV, http=clouds, oci_client=vault)
        return answer, clouds

    def test_every_step_passes(self):
        answer, clouds = self.run_chain()
        self.assertTrue(answer["passed"], json.dumps(answer, indent=1))
        steps = answer["steps"]
        self.assertEqual(list(steps), ["config", "discovery", "token", "sts", "tampered", "account", "gcs", "control"])
        self.assertEqual(steps["token"]["attempts"], [{"header": "x5t", "status": 200, "tokenType": "Bearer",
                                                       "expiresIn": 3600}])
        self.assertTrue(steps["token"]["audienceMatches"])
        self.assertEqual(steps["tampered"]["code"], "invalid_grant")
        self.assertTrue(steps["gcs"]["object"].startswith("oci-lab/"))
        self.assertIn(steps["gcs"]["object"], clouds.objects)
        self.assertEqual(steps["control"]["status"], 403)

    def test_the_answer_carries_no_token(self):
        answer, clouds = self.run_chain()
        text = json.dumps(answer)
        for secret in (clouds.access_token, FEDERATED, ACCESS):
            self.assertNotIn(secret, text)

    def test_a_default_issuer_is_reported(self):
        answer, _ = self.run_chain(issuer="https://identity.oraclecloud.com/")
        self.assertFalse(answer["steps"]["discovery"]["issuerIsDomain"])
        self.assertFalse(answer["passed"])

    def test_kid_is_tried_when_x5t_alone_is_refused(self):
        answer, _ = self.run_chain(refuse_x5t_only=True)
        attempts = answer["steps"]["token"]["attempts"]
        self.assertEqual([a["header"] for a in attempts], ["x5t", "x5t+kid"])
        self.assertEqual(attempts[0]["error"], "invalid_client")
        self.assertTrue(answer["steps"]["token"]["ok"])

    def test_a_refused_service_account_stops_before_storage(self):
        answer, clouds = self.run_chain(account_denied=True)
        self.assertEqual(answer["steps"]["account"]["code"], "PERMISSION_DENIED")
        self.assertNotIn("gcs", answer["steps"])
        self.assertFalse(answer["passed"])
        self.assertFalse(any(urllib.parse.urlsplit(u).netloc == "storage.googleapis.com" for _, u, _ in clouds.requests))

    def test_missing_configuration_is_named(self):
        environ = {k: v for k, v in TEST_ENV.items() if k not in ("OCI_CLIENT_ID", "GOOGLE_STORAGE_BUCKET_NAME_LAB")}
        answer = lab.handle(b"", environ=environ, http=object(), oci_client=object())
        self.assertEqual(answer["steps"]["config"]["missing"], ["OCI_CLIENT_ID", "GOOGLE_STORAGE_BUCKET_NAME_<label>"])
        self.assertFalse(answer["passed"])

    def test_a_prefixed_provider_is_accepted(self):
        self.assertEqual(lab.provider_name(f"//iam.googleapis.com/{PROVIDER}"), PROVIDER)
        self.assertEqual(lab.provider_name(PROVIDER), PROVIDER)

    def test_tampered_token_differs_only_in_the_signature(self):
        token = unsigned_jwt({"a": 1})
        changed = lab.tampered(token)
        self.assertNotEqual(changed, token)
        self.assertEqual(changed.split(".")[:2], token.split(".")[:2])


if __name__ == "__main__":
    unittest.main()
