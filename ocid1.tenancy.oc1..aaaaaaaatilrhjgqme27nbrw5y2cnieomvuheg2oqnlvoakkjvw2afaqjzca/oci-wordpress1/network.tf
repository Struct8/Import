resource "oci_core_vcn" "wp-net1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "wp-net1"
  cidr_blocks    = ["10.0.0.0/16"]
  freeform_tags = {
    Name           = "wp-net1"
    State          = "oci-wordpress1"
    Struct8Creator = "Contato Struct"
  }
}

resource "oci_core_subnet" "web1" {
  compartment_id            = oci_identity_compartment.wordpress1.id
  display_name              = "web1"
  route_table_id            = oci_core_route_table.public-rt1.id
  vcn_id                    = oci_core_vcn.wp-net1.id
  cidr_block                = "10.0.0.0/24"
  prohibit_internet_ingress = false
  freeform_tags = {
    Name           = "web1"
    State          = "oci-wordpress1"
    Struct8Creator = "Contato Struct"
  }
}

resource "oci_core_internet_gateway" "wp-igw1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "wp-igw1"
  vcn_id         = oci_core_vcn.wp-net1.id
  freeform_tags = {
    Name           = "wp-igw1"
    State          = "oci-wordpress1"
    Struct8Creator = "Contato Struct"
  }
}

resource "oci_core_route_table" "public-rt1" {
  compartment_id = oci_identity_compartment.wordpress1.id
  display_name   = "public-rt1"
  vcn_id         = oci_core_vcn.wp-net1.id
  freeform_tags = {
    Name           = "public-rt1"
    State          = "oci-wordpress1"
    Struct8Creator = "Contato Struct"
  }
  route_rules {
    network_entity_id = oci_core_internet_gateway.wp-igw1.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}
