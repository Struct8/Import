resource "oci_identity_domains_app" "Debugwp_debug_caller" {
  display_name    = "struct8-debug-WrkdhoSWvJzzYBOR4SPvz"
  name            = "struct8-debug-WrkdhoSWvJzzYBOR4SPvz"
  active          = true
  allowed_grants  = ["client_credentials"]
  client_type     = "trusted"
  description     = "Struct8 runs commands on the instances of the Debug Access component Debugwp as this application."
  force_delete    = true
  idcs_endpoint   = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com"
  is_oauth_client = true
  schemas         = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]
  based_on_template {
    value = "CustomWebAppTemplateId"
  }
  certificates {
    cert_alias = oci_identity_domains_oauth_client_certificate.Debugwp_debug_caller.certificate_alias
  }
  lifecycle {
    ignore_changes = [schemas]
  }
}

resource "oci_identity_domains_identity_propagation_trust" "Debugwp_debug_caller" {
  name                   = "struct8-debug-WrkdhoSWvJzzYBOR4SPvz"
  active                 = true
  allow_impersonation    = true
  claim_propagations     = ["ext_struct8_deputy", "ext_struct8_debug", "ext_struct8_debug_level"]
  description            = "Struct8 runs commands on the instances of the Debug Access component Debugwp as this application."
  idcs_endpoint          = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com"
  impersonating_resource = "struct8_debug"
  issuer                 = "https://struct8.com/oidc/oci/debug/WrkdhoSWvJzzYBOR4SPvz"
  oauth_clients          = [oci_identity_domains_app.Debugwp_debug_caller.name]
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
    value = "WrkdhoSWvJzzYBOR4SPvz"
  }
  claim_validations {
    name  = "struct8_debug_level"
    value = "shell"
  }
}

resource "oci_identity_domains_oauth_client_certificate" "Debugwp_debug_caller" {
  certificate_alias     = "struct8-debug-WrkdhoSWvJzzYBOR4SPvz"
  idcs_endpoint         = "https://idcs-b4fd5c4293ab48539b64c95eeb70df35.identity.oraclecloud.com"
  schemas               = ["urn:ietf:params:scim:schemas:oracle:idcs:OAuthClientCertificate"]
  x509base64certificate = data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].public_certificate
}

resource "oci_identity_dynamic_group" "Debugwp_debug" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-WrkdhoSWvJzzYBOR4SPvz"
  description    = "Compute instances the Debug Access component Debugwp runs commands on."
  matching_rule  = "ANY {instance.id = '${oci_core_instance.wordpress.id}'}"
}

resource "oci_identity_policy" "Debugwp_debug" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-WrkdhoSWvJzzYBOR4SPvz-run-command"
  description    = "Lets the instances of the Debug Access component Debugwp read and answer the commands sent to each of them."
  statements     = ["Allow dynamic-group id ${oci_identity_dynamic_group.Debugwp_debug.id} to use instance-agent-command-execution-family in compartment id ${oci_identity_compartment.wordpress.id} where request.instance.id = target.instance.id"]
}

resource "oci_identity_policy" "Debugwp_debug_caller" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-WrkdhoSWvJzzYBOR4SPvz-caller"
  description    = "Lets Struct8 run commands on the instances of the Debug Access component Debugwp and read their output."
  statements     = ["Allow any-user to use instance-agent-commands in compartment id ${oci_identity_compartment.wordpress.id} where all {request.principal.type = 'identityfederateddomainapp', request.principal.ext_struct8_deputy = '${one([for c in data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].claim_validations : c.value if c.name == "struct8_deputy"])}', request.principal.ext_struct8_debug = 'WrkdhoSWvJzzYBOR4SPvz', target.instance.id = '${oci_core_instance.wordpress.id}'}", "Allow any-user to read instances in compartment id ${oci_identity_compartment.wordpress.id} where all {request.principal.type = 'identityfederateddomainapp', request.principal.ext_struct8_deputy = '${one([for c in data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].claim_validations : c.value if c.name == "struct8_deputy"])}', request.principal.ext_struct8_debug = 'WrkdhoSWvJzzYBOR4SPvz', target.instance.id = '${oci_core_instance.wordpress.id}'}", "Allow any-user to read instance-agent-command-executions in compartment id ${oci_identity_compartment.wordpress.id} where all {request.principal.type = 'identityfederateddomainapp', request.principal.ext_struct8_deputy = '${one([for c in data.oci_identity_domains_identity_propagation_trusts.struct8_reader.identity_propagation_trusts[0].claim_validations : c.value if c.name == "struct8_deputy"])}', request.principal.ext_struct8_debug = 'WrkdhoSWvJzzYBOR4SPvz', target.instance.id = '${oci_core_instance.wordpress.id}'}"]
  depends_on     = [oci_identity_domains_identity_propagation_trust.Debugwp_debug_caller]
}

resource "oci_identity_policy" "mysql_db_system_nsgs" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "oci-wordpress-mysql-nsgs-sa-saopaulo-1"
  description    = "Lets the MySQL HeatWave DB systems of oci-wordpress in sa-saopaulo-1 attach their VNICs to network security groups."
  statements     = ["Allow any-user to {VNIC_CREATE, VNIC_UPDATE, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment id ${oci_identity_compartment.wordpress.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.wordpress.id}'}", "Allow any-user to {NETWORK_SECURITY_GROUP_UPDATE_MEMBERS} in compartment id ${oci_identity_compartment.wordpress.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.wordpress.id}'}"]
}
