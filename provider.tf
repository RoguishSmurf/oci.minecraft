provider "oci" {
    auth = "InstancePrincipal"
    region = var.region
}

variable "region" {}
variable "tenancy_id" {}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_id
}

output "ads" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}