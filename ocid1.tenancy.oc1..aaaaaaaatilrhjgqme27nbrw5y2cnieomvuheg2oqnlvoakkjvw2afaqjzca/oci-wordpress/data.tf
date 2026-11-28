data "oci_core_images" "wordpress_image" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaatilrhjgqme27nbrw5y2cnieomvuheg2oqnlvoakkjvw2afaqjzca"
  shape          = "VM.Standard1.1"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
  filter {
    name   = "display_name"
    regex  = true
    values = ["^Oracle-Linux-10(\\.[0-9]+)?(-aarch64)?-[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}-[0-9]+$"]
  }
}
