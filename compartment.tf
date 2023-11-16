resource "oci_identity_compartment" "minecraft" {
    #Required
    compartment_id  = var.tenancy_id
    description     = "Minecraft Application"
    name            = "minecraft"
    #Optional
    enable_delete   = false
}

resource "oci_identity_tag_namespace" "minecraft_tags_ns" {
    compartment_id = oci_identity_compartment.minecraft.id
    description = "Minecraft Tags"
    name = "minecraft"
}

resource "oci_identity_tag" "role" {
    description = "Server Role"
    name = "role"
    tag_namespace_id = oci_identity_tag_namespace.minecraft_tags_ns.id
    validator {
        validator_type = "ENUM"
        values = ["loadbalancer", "minecraft"]
    }
}

resource "oci_identity_tag" "game" {
    description = "Game"
    name = "game"
    tag_namespace_id = oci_identity_tag_namespace.minecraft_tags_ns.id
    validator {
        validator_type = "ENUM"
        values = ["lobby", "survival", "dev"]
    }
}