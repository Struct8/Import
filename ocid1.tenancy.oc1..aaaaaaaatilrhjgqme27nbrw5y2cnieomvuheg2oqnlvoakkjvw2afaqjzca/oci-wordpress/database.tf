resource "oci_mysql_mysql_db_system" "wordpress-db" {
  compartment_id          = oci_identity_compartment.wordpress.id
  display_name            = "wordpress-db"
  shape_name              = "MySQL.Free"
  subnet_id               = oci_core_subnet.db.id
  admin_password          = "Troque-Esta-Senha-1"
  admin_username          = "wpadmin"
  availability_domain     = data.oci_identity_availability_domains.ads.availability_domains[0].name
  data_storage_size_in_gb = 50
  ip_address              = "10.0.1.10"
  is_highly_available     = false
  nsg_ids                 = [oci_core_network_security_group.db-nsg.id]
  state                   = "ACTIVE"
}
