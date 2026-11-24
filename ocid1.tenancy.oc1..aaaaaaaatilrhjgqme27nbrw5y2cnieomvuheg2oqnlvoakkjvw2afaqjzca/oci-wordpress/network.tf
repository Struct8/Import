resource "oci_core_vcn" "wp-net" {
  compartment_id = oci_identity_compartment.wordpress.id
  display_name   = "wp-net"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "db" {
  compartment_id            = oci_identity_compartment.wordpress.id
  display_name              = "db"
  vcn_id                    = oci_core_vcn.wp-net.id
  cidr_block                = "10.0.1.0/24"
  prohibit_internet_ingress = true
}

resource "oci_core_subnet" "web" {
  compartment_id            = oci_identity_compartment.wordpress.id
  display_name              = "web"
  route_table_id            = oci_core_route_table.public-rt.id
  vcn_id                    = oci_core_vcn.wp-net.id
  cidr_block                = "10.0.0.0/24"
  prohibit_internet_ingress = false
}

resource "oci_core_internet_gateway" "wp-igw" {
  compartment_id = oci_identity_compartment.wordpress.id
  display_name   = "wp-igw"
  vcn_id         = oci_core_vcn.wp-net.id
}

resource "oci_core_route_table" "public-rt" {
  compartment_id = oci_identity_compartment.wordpress.id
  display_name   = "public-rt"
  vcn_id         = oci_core_vcn.wp-net.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.wp-igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_network_security_group" "wordpress_nsg" {
  compartment_id = oci_identity_compartment.wordpress.id
  display_name   = "wordpress_nsg"
  vcn_id         = oci_core_vcn.wp-net.id
}

resource "oci_core_network_security_group_security_rule" "wordpress_nsg_cidr_in_tcp_443_0_0_0_0_0" {
  source                    = "0.0.0.0/0"
  network_security_group_id = oci_core_network_security_group.wordpress_nsg.id
  description               = "HTTPS"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "wordpress_nsg_cidr_in_tcp_80_0_0_0_0_0" {
  source                    = "0.0.0.0/0"
  network_security_group_id = oci_core_network_security_group.wordpress_nsg.id
  description               = "HTTP"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}
