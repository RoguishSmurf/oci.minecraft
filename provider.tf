provider "oci" {
  # Cloud Shell Authentiation
  auth = "InstancePrincipal"
  region = var.region

  # Local Shell Authentication
  # config_file_profile=var.config_file_profile
}

variable "region" {}
variable "tenancy_id" {}
variable "config_file_profile" {
  default = "DEFAULT"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_id
}

output "ads" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}