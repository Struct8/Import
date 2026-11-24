resource "oci_core_vcn" "wp-net2" {
  compartment_id = oci_identity_compartment.wordpress2.id
  display_name   = "wp-net2"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "db2" {
  compartment_id            = oci_identity_compartment.wordpress2.id
  display_name              = "db2"
  vcn_id                    = oci_core_vcn.wp-net2.id
  cidr_block                = "10.0.1.0/24"
  prohibit_internet_ingress = true
}

resource "oci_core_subnet" "web2" {
  compartment_id            = oci_identity_compartment.wordpress2.id
  display_name              = "web2"
  route_table_id            = oci_core_route_table.public-rt2.id
  vcn_id                    = oci_core_vcn.wp-net2.id
  cidr_block                = "10.0.0.0/24"
  prohibit_internet_ingress = false
}

resource "oci_core_internet_gateway" "wp-igw2" {
  compartment_id = oci_identity_compartment.wordpress2.id
  display_name   = "wp-igw2"
  vcn_id         = oci_core_vcn.wp-net2.id
}

resource "oci_core_route_table" "public-rt2" {
  compartment_id = oci_identity_compartment.wordpress2.id
  display_name   = "public-rt2"
  vcn_id         = oci_core_vcn.wp-net2.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.wp-igw2.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_network_security_group" "db-nsg2" {
  compartment_id = oci_identity_compartment.wordpress2.id
  display_name   = "db-nsg2"
  vcn_id         = oci_core_vcn.wp-net2.id
}

resource "oci_core_network_security_group" "web-nsg2" {
  compartment_id = oci_identity_compartment.wordpress2.id
  display_name   = "web-nsg2"
  vcn_id         = oci_core_vcn.wp-net2.id
}

resource "oci_core_network_security_group_security_rule" "nsg_rule2_in_tcp_3306" {
  source                    = oci_core_network_security_group.web-nsg2.id
  network_security_group_id = oci_core_network_security_group.db-nsg2.id
  description               = "MySQL"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      max = 3306
      min = 3306
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nsg_rule2_in_tcp_33060" {
  source                    = oci_core_network_security_group.web-nsg2.id
  network_security_group_id = oci_core_network_security_group.db-nsg2.id
  description               = "MySQL X Protocol"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "NETWORK_SECURITY_GROUP"
  tcp_options {
    destination_port_range {
      max = 33060
      min = 33060
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nsg_rule2_out_tcp_3306" {
  network_security_group_id = oci_core_network_security_group.web-nsg2.id
  description               = "MySQL"
  destination               = oci_core_network_security_group.db-nsg2.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  direction                 = "EGRESS"
  protocol                  = "6"
  tcp_options {
    destination_port_range {
      max = 3306
      min = 3306
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nsg_rule2_out_tcp_33060" {
  network_security_group_id = oci_core_network_security_group.web-nsg2.id
  description               = "MySQL X Protocol"
  destination               = oci_core_network_security_group.db-nsg2.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  direction                 = "EGRESS"
  protocol                  = "6"
  tcp_options {
    destination_port_range {
      max = 33060
      min = 33060
    }
  }
}

resource "oci_core_network_security_group_security_rule" "web_nsg2_cidr_in_tcp_443_0_0_0_0_0" {
  source                    = "0.0.0.0/0"
  network_security_group_id = oci_core_network_security_group.web-nsg2.id
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

resource "oci_core_network_security_group_security_rule" "web_nsg2_cidr_in_tcp_80_0_0_0_0_0" {
  source                    = "0.0.0.0/0"
  network_security_group_id = oci_core_network_security_group.web-nsg2.id
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
