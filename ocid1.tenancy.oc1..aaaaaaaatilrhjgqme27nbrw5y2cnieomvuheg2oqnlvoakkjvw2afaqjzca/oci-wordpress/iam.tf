resource "oci_identity_policy" "mysql_db_system_nsgs" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  name           = "oci-wordpress-mysql-nsgs-sa-saopaulo-1"
  description    = "Lets the MySQL HeatWave DB systems of oci-wordpress in sa-saopaulo-1 attach their VNICs to network security groups."
  statements     = ["Allow any-user to {VNIC_CREATE, VNIC_UPDATE, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment id ${oci_identity_compartment.wordpress.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.wordpress.id}'}", "Allow any-user to {NETWORK_SECURITY_GROUP_UPDATE_MEMBERS} in compartment id ${oci_identity_compartment.wordpress.id} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${oci_identity_compartment.wordpress.id}'}"]
}
