resource "oci_core_vcn" "wp-net1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "wp-net1"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "db1" {
  compartment_id            = oci_identity_compartment.wordpress1.id
  display_name              = "db1"
  vcn_id                    = oci_core_vcn.wp-net1.id
  cidr_block                = "10.0.1.0/24"
  prohibit_internet_ingress = true
}

resource "oci_core_subnet" "web1" {
  compartment_id            = oci_identity_compartment.wordpress1.id
  display_name              = "web1"
  route_table_id            = oci_core_route_table.public-rt1.id
  vcn_id                    = oci_core_vcn.wp-net1.id
  cidr_block                = "10.0.0.0/24"
  prohibit_internet_ingress = false
}

resource "oci_core_internet_gateway" "wp-igw1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "wp-igw1"
  vcn_id         = oci_core_vcn.wp-net1.id
}

resource "oci_core_route_table" "public-rt1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "public-rt1"
  vcn_id         = oci_core_vcn.wp-net1.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.wp-igw1.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_network_security_group" "db-nsg1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "db-nsg1"
  vcn_id         = oci_core_vcn.wp-net1.id
}

resource "oci_core_network_security_group" "web-nsg1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "web-nsg1"
  vcn_id         = oci_core_vcn.wp-net1.id
}

resource "oci_core_network_security_group_security_rule" "nsg_rule1_in_tcp_3306" {
  source                    = oci_core_network_security_group.web-nsg1.id
  network_security_group_id = oci_core_network_security_group.db-nsg1.id
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

resource "oci_core_network_security_group_security_rule" "nsg_rule1_in_tcp_33060" {
  source                    = oci_core_network_security_group.web-nsg1.id
  network_security_group_id = oci_core_network_security_group.db-nsg1.id
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

resource "oci_core_network_security_group_security_rule" "nsg_rule1_out_tcp_3306" {
  network_security_group_id = oci_core_network_security_group.web-nsg1.id
  description               = "MySQL"
  destination               = oci_core_network_security_group.db-nsg1.id
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

resource "oci_core_network_security_group_security_rule" "nsg_rule1_out_tcp_33060" {
  network_security_group_id = oci_core_network_security_group.web-nsg1.id
  description               = "MySQL X Protocol"
  destination               = oci_core_network_security_group.db-nsg1.id
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

resource "oci_core_network_security_group_security_rule" "web_nsg1_cidr_in_tcp_443_0_0_0_0_0" {
  source                    = "0.0.0.0/0"
  network_security_group_id = oci_core_network_security_group.web-nsg1.id
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

resource "oci_core_network_security_group_security_rule" "web_nsg1_cidr_in_tcp_80_0_0_0_0_0" {
  source                    = "0.0.0.0/0"
  network_security_group_id = oci_core_network_security_group.web-nsg1.id
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
