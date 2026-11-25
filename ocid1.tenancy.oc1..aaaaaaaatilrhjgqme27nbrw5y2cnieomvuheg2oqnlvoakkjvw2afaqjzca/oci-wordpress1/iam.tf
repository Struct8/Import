resource "oci_identity_dynamic_group" "wp-debug1_debug" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-IKvQlk2Lk8gjbC2iRQ-H5"
  description    = "Compute instances the Debug Access component wp-debug1 runs commands on."
  matching_rule  = "ANY {instance.id = '${oci_core_instance.wordpress1.id}'}"
  provider       = oci.home
}

resource "oci_identity_policy" "wp-debug1_debug" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "Struct8Debug-IKvQlk2Lk8gjbC2iRQ-H5-run-command"
  description    = "Lets the instances of the Debug Access component wp-debug1 read and answer the commands sent to each of them."
  provider       = oci.home
  statements     = ["Allow dynamic-group id ${oci_identity_dynamic_group.wp-debug1_debug.id} to use instance-agent-command-execution-family in compartment id ${oci_identity_compartment.wordpress1.id} where request.instance.id = target.instance.id"]
}
