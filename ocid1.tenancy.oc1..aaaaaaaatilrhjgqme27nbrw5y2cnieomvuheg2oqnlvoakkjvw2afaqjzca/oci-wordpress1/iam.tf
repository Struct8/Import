resource "oci_identity_domains_app" "wp-debug1_debug_caller" {
  display_name    = "struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5"
  name            = "struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5"
  active          = true
  allowed_grants  = ["client_credentials"]
  client_type     = "trusted"
  description     = "Struct8 runs commands on the instances of the Debug Access component wp-debug1 as this application."
  force_delete    = true
  idcs_endpoint   = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com"
  is_oauth_client = true
  schemas         = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]
  based_on_template {
    value = "CustomWebAppTemplateId"
  }
  certificates {
    cert_alias = oci_identity_domains_oauth_client_certificate.wp-debug1_debug_caller.certificate_alias
  }
  lifecycle {
    ignore_changes = [schemas]
  }
}

resource "oci_identity_domains_identity_propagation_trust" "wp-debug1_debug_caller" {
  name                   = "struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5"
  active                 = true
  allow_impersonation    = true
  claim_propagations     = ["ext_struct8_deputy", "ext_struct8_debug", "ext_struct8_debug_level"]
  description            = "Struct8 runs commands on the instances of the Debug Access component wp-debug1 as this application."
  idcs_endpoint          = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com"
  impersonating_resource = "struct8_debug"
  issuer                 = "https://struct8.com/oidc/oci/debug/IKvQlk2Lk8gjbC2iRQ-H5"
  oauth_clients          = [oci_identity_domains_app.wp-debug1_debug_caller.name]
  public_certificate     = data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].public_certificate
  schemas                = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"]
  subject_type           = "Resource"
  type                   = "JWT"
  claim_validations {
    name  = "struct8_deputy"
    value = one([for c in data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].claim_validations : c.value if c.name == "struct8_deputy"])
  }
  claim_validations {
    name  = "struct8_debug"
    value = "IKvQlk2Lk8gjbC2iRQ-H5"
  }
  claim_validations {
    name  = "struct8_debug_level"
    value = "shell"
  }
}

resource "oci_identity_domains_oauth_client_certificate" "wp-debug1_debug_caller" {
  certificate_alias     = "struct8-debug-IKvQlk2Lk8gjbC2iRQ-H5"
  idcs_endpoint         = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com"
  schemas               = ["urn:ietf:params:scim:schemas:oracle:idcs:OAuthClientCertificate"]
  x509base64certificate = data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].public_certificate
}

resource "oci_identity_dynamic_group" "wp-debug1_debug" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-IKvQlk2Lk8gjbC2iRQ-H5"
  description    = "Compute instances the Debug Access component wp-debug1 runs commands on."
  matching_rule  = "ANY {instance.id = '${oci_core_instance.wordpress1.id}'}"
}

resource "oci_identity_policy" "wp-debug1_debug" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-IKvQlk2Lk8gjbC2iRQ-H5-run-command"
  description    = "Lets the instances of the Debug Access component wp-debug1 read and answer the commands sent to each of them."
  statements     = ["Allow dynamic-group id ${oci_identity_dynamic_group.wp-debug1_debug.id} to use instance-agent-command-execution-family in compartment id ${oci_identity_compartment.wordpress1.id} where request.instance.id = target.instance.id"]
}

resource "oci_identity_policy" "wp-debug1_debug_caller" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-IKvQlk2Lk8gjbC2iRQ-H5-caller"
  description    = "Lets Struct8 run commands on the instances of the Debug Access component wp-debug1 and read their output."
  statements     = ["Allow any-user to use instance-agent-commands in compartment id ${oci_identity_compartment.wordpress1.id} where all {request.principal.type = 'identityfederateddomainapp', request.principal.ext_struct8_deputy = '${one([for c in data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].claim_validations : c.value if c.name == "struct8_deputy"])}', request.principal.ext_struct8_debug = 'IKvQlk2Lk8gjbC2iRQ-H5', target.instance.id = '${oci_core_instance.wordpress1.id}'}", "Allow any-user to read instances in compartment id ${oci_identity_compartment.wordpress1.id} where all {request.principal.type = 'identityfederateddomainapp', request.principal.ext_struct8_deputy = '${one([for c in data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].claim_validations : c.value if c.name == "struct8_deputy"])}', request.principal.ext_struct8_debug = 'IKvQlk2Lk8gjbC2iRQ-H5', target.instance.id = '${oci_core_instance.wordpress1.id}'}", "Allow any-user to read instance-agent-command-executions in compartment id ${oci_identity_compartment.wordpress1.id} where all {request.principal.type = 'identityfederateddomainapp', request.principal.ext_struct8_deputy = '${one([for c in data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].claim_validations : c.value if c.name == "struct8_deputy"])}', request.principal.ext_struct8_debug = 'IKvQlk2Lk8gjbC2iRQ-H5', target.instance.id = '${oci_core_instance.wordpress1.id}'}"]
  depends_on     = [oci_identity_domains_identity_propagation_trust.wp-debug1_debug_caller]
}
