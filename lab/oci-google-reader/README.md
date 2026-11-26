# OCI function to Google Cloud Storage, lab

Temporary lab code for direction (10) of `docs/cross-cloud-oci-matriz-plano.md`
in the CloudMan repository: an OCI function exchanges an access token of an OCI
identity domain for a federated token of the workload identity pool of a
`cldmn_workload_identity` component in a Google Cloud state, impersonates the
component's service account, and writes, reads and lists objects in a Cloud
Storage bucket. This branch is deleted when the lab ends.

- `lab_caller.py`: the chain and the certificate action (docstring at the top).
- `func.py`: the fdk entry point.
- `test_lab_caller.py`: `python -m unittest test_lab_caller`, standard library
  plus `cryptography`, against fakes of the Vault, the domain and Google.

Invoke with `{"action": "certificate"}` first: the PEM goes in the
component's `oci_client_certificate_` field. Then `{"action": "test"}`.
