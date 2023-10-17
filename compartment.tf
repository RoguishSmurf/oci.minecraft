resource "oci_identity_compartment" "minecraft" {
    #Required
    compartment_id  = var.tenancy_id
    description     = "Minecraft Application"
    name            = "minecraft"
    #Optional
    enable_delete   = false
}