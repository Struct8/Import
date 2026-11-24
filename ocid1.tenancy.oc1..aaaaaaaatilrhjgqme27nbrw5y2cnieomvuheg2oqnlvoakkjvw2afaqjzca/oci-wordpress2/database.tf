resource "oci_mysql_mysql_db_system" "wordpress-db2" {
  compartment_id          = oci_identity_compartment.wordpress2.id
  display_name            = "wordpress-db2"
  shape_name              = "MySQL.Free"
  subnet_id               = oci_core_subnet.db2.id
  admin_password          = "Troque-Esta-Senha-1"
  admin_username          = "wpadmin"
  availability_domain     = data.oci_identity_availability_domains.ads.availability_domains[0].name
  data_storage_size_in_gb = 50
  ip_address              = "10.0.1.10"
  is_highly_available     = false
  nsg_ids                 = [oci_core_network_security_group.db-nsg2.id]
  state                   = "ACTIVE"
}
