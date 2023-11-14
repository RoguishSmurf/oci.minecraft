variable "shape"     { default="VM.Standard.E4.Flex" }
variable "burstable" { default="BASELINE_1_2" }
variable "cpus"      { default="1" }
variable "memory"    { default="8" }
variable "cpus_minecraft"      { default="1" }
variable "memory_minecraft"    { default="12" }

data "oci_core_images" "linux_images" {
    compartment_id           = oci_identity_compartment.minecraft.id
    operating_system         = "Oracle Linux"
    operating_system_version = "8"
    sort_by                  = "TIMECREATED"
    sort_order               = "DESC"
}

resource "tls_private_key" "public_private_key_pair" {
  algorithm   = "RSA"
}

resource "oci_core_instance" "bastion" {
    compartment_id      = oci_identity_compartment.minecraft.id
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    display_name        = "Minecraft Bastion"

    shape = var.shape
    shape_config {
        memory_in_gbs = var.memory
        ocpus         = var.cpus
        baseline_ocpu_utilization = var.burstable
    }

    create_vnic_details {
        subnet_id        = oci_core_subnet.dmz.id
        assign_public_ip = true
        hostname_label   = "bastion"
        nsg_ids          = [oci_core_network_security_group.minecraft_dmz.id]
    }

    metadata = {
      ssh_authorized_keys = tls_private_key.public_private_key_pair.public_key_openssh
    }

    source_details {
        # https://docs.oracle.com/en-us/iaas/images/image/e1a40b7b-4d0b-461f-9078-0d2da7283349
        source_id   = data.oci_core_images.linux_images.images[0].id
        source_type = "image"
    }

    lifecycle {
      ignore_changes = [source_details, metadata]
    }
}

output "bastion_public_ip" {
    value = oci_core_instance.bastion.public_ip
}

output "private_ssh_key" {
    value = tls_private_key.public_private_key_pair.private_key_openssh
    sensitive = true
}

resource "oci_core_instance" "minecraft" {
    compartment_id      = oci_identity_compartment.minecraft.id
    availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
    display_name        = "Minecraft Server"

    shape = var.shape
    shape_config {
        memory_in_gbs = var.memory
        ocpus         = var.cpus
        baseline_ocpu_utilization = var.burstable
    }

    create_vnic_details {
        subnet_id        = oci_core_subnet.apps.id
        hostname_label   = "minecraft"
        assign_public_ip = false
        nsg_ids          = [oci_core_network_security_group.minecraft_app.id]
    }

    metadata = {
      ssh_authorized_keys = tls_private_key.public_private_key_pair.public_key_openssh
    }

    source_details {
        # https://docs.oracle.com/en-us/iaas/images/image/e1a40b7b-4d0b-461f-9078-0d2da7283349
        source_id   = data.oci_core_images.linux_images.images[0].id
        source_type = "image"
    }

    lifecycle {
      ignore_changes = [source_details, metadata]
    }
}

resource "ansible_host" "bastion" {
  name   = oci_core_instance.bastion.public_ip
  groups = ["bastion", "loadbalancer"]
}

resource "ansible_host" "minecraft" {
  name   = oci_core_instance.bastion.private_ip
  groups = ["minecraft", "apps"]
}