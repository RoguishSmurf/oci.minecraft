resource "oci_objectstorage_bucket" "state_bucket" {
	compartment_id = var.tenancy_id
	name = var.bucket_name
	namespace = var.bucket_namespace
}