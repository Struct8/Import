resource "oci_core_vcn" "oci-google-net" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "oci-google-net"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "functions" {
  compartment_id            = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name              = "functions"
  route_table_id            = oci_core_route_table.private-rt.id
  vcn_id                    = oci_core_vcn.oci-google-net.id
  cidr_block                = "10.0.1.0/24"
  prohibit_internet_ingress = true
}

resource "oci_core_nat_gateway" "oci-google-nat" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "oci-google-nat"
  vcn_id         = oci_core_vcn.oci-google-net.id
  block_traffic  = false
}

data "oci_core_services" "oci-google-sgw_services" {
  filter {
    name   = "name"
    regex  = true
    values = ["All .* Services [Ii]n Oracle Services Network"]
  }
}

resource "oci_core_service_gateway" "oci-google-sgw" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "oci-google-sgw"
  vcn_id         = oci_core_vcn.oci-google-net.id
  services {
    service_id = data.oci_core_services.oci-google-sgw_services.services[0].id
  }
}

data "oci_core_services" "private-rt_service_label" {
  filter {
    name   = "name"
    regex  = true
    values = ["All .* Services [Ii]n Oracle Services Network"]
  }
}

resource "oci_core_route_table" "private-rt" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "private-rt"
  vcn_id         = oci_core_vcn.oci-google-net.id
  route_rules {
    network_entity_id = oci_core_nat_gateway.oci-google-nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
  route_rules {
    network_entity_id = oci_core_service_gateway.oci-google-sgw.id
    destination       = data.oci_core_services.private-rt_service_label.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_network_security_group" "oci-google-lab_nsg" {
  compartment_id = one([for it in data.oci_identity_compartments.lab-oci-google.compartments : it.id if it.name == "lab-oci-google"])
  display_name   = "oci-google-lab_nsg"
  vcn_id         = oci_core_vcn.oci-google-net.id
}
