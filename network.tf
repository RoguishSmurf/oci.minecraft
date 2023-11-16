resource "oci_core_vcn" "minecraft" {
    # Required
    compartment_id  = oci_identity_compartment.minecraft.id
    cidr_blocks     = ["192.168.0.0/16"]
    # Optional
    dns_label       = "minecraft"
    display_name    = "minecraft-vcn"
    is_ipv6enabled  = false
}

# Internet Gateway
resource "oci_core_internet_gateway" "minecraft" {
    # Required
    compartment_id = oci_identity_compartment.minecraft.id
    vcn_id         = oci_core_vcn.minecraft.id
    # Optional
    enabled        = true
    display_name   = "minecraft-ig"
}

# NAT Gateway
resource "oci_core_nat_gateway" "minecraft" {
    # Required
    compartment_id = oci_identity_compartment.minecraft.id
    vcn_id         = oci_core_vcn.minecraft.id
    # Optional
    display_name   = "minecraft-nat"
    block_traffic  = false
}

# Get All OCI Services OCID
data "oci_core_services" "all_services" {
    filter {
        name = "cidr_block"
				values = ["all-*"]
        regex = true
    }
}

# Service Gateway
resource "oci_core_service_gateway" "minecraft" {
    # Required
    compartment_id = oci_identity_compartment.minecraft.id
    vcn_id         = oci_core_vcn.minecraft.id
    services {
        service_id = data.oci_core_services.all_services.services[0].id
    }
    # Optional
    display_name   = "minecraft-sg"
}

# Create Public Route Table
resource "oci_core_route_table" "minecraft_public_rt" {
    # Required
    compartment_id = oci_identity_compartment.minecraft.id
    vcn_id         = oci_core_vcn.minecraft.id
    route_rules    {
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        network_entity_id = oci_core_internet_gateway.minecraft.id
    }
    # Optional
    display_name   = "minecraft-ig-rt"
}

# Create Private Route Table
# Update VCN Default Route Table
resource "oci_core_default_route_table" "minecraft_private_rt" {
    # Required
    manage_default_resource_id = oci_core_vcn.minecraft.default_route_table_id
    route_rules    {
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        network_entity_id = oci_core_nat_gateway.minecraft.id
    }
    route_rules    {
        destination_type  = "SERVICE_CIDR_BLOCK"
        destination       = data.oci_core_services.all_services.services[0].cidr_block
        network_entity_id = oci_core_service_gateway.minecraft.id
    }
    # Optional
    display_name   = "minecraft-nat-rt"
}

# DHCP Options
# Update VCN Default DHCP Option
resource "oci_core_default_dhcp_options" "minecraft" {
    # Required
    manage_default_resource_id = oci_core_vcn.minecraft.default_dhcp_options_id
    options    {
        type  = "DomainNameServer"
        server_type = "VcnLocalPlusInternet"
    }
    options    {
        type  = "SearchDomain"
        search_domain_names      = ["minecraft.oraclevcn.com"]
    }
    # Optional
    display_name   = "minecraft-dns"
}

# Apps Private Subnet
resource "oci_core_subnet" "apps" {
    # Required
    compartment_id             = oci_identity_compartment.minecraft.id
    vcn_id                     = oci_core_vcn.minecraft.id
    cidr_block                 = "192.168.1.0/24"
    # Optional 
    display_name               = "apps"
    dns_label                  = "apps"
    route_table_id             = oci_core_default_route_table.minecraft_private_rt.id
    dhcp_options_id            = oci_core_default_dhcp_options.minecraft.id
    prohibit_public_ip_on_vnic = true
}

# DMZ Public Subnet
resource "oci_core_subnet" "dmz" {
    # Required
    compartment_id             = oci_identity_compartment.minecraft.id
    vcn_id                     = oci_core_vcn.minecraft.id
    cidr_block                 = "192.168.0.0/24"
    # Optional 
    display_name               = "dmz"
    dns_label                  = "dmz"
    route_table_id             = oci_core_route_table.minecraft_public_rt.id
    dhcp_options_id            = oci_core_default_dhcp_options.minecraft.id
    prohibit_public_ip_on_vnic = false
}

# Network Security Group
resource "oci_core_network_security_group" "minecraft_app" {
    # Required
    compartment_id             = oci_identity_compartment.minecraft.id
    vcn_id                     = oci_core_vcn.minecraft.id
    # Optional
    display_name   = "minecraft-app-nsg"
}

resource "oci_core_network_security_group" "minecraft_dmz" {
    # Required
    compartment_id             = oci_identity_compartment.minecraft.id
    vcn_id                     = oci_core_vcn.minecraft.id
    # Optional
    display_name   = "minecraft-dmz-nsg"
}

# Network Security Group Rules
resource "oci_core_network_security_group_security_rule" "minecraft_from_dmz" {
    # Required
    network_security_group_id = oci_core_network_security_group.minecraft_app.id
    direction         = "INGRESS"
    protocol          = "6"
    # Optional
    description       = "minecraft-from-dmz"
    destination       = "192.168.1.0/24" # App
    # destination_type  = "CIDR_BLOCK" # Optional on Ingress
    source            = "192.168.0.0/24" # DMZ
    tcp_options {
        destination_port_range {
            min = "25565"
            max = "25565"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "proxy_from_dmz" {
    # Required
    network_security_group_id = oci_core_network_security_group.minecraft_app.id
    direction         = "INGRESS"
    protocol          = "6"
    # Optional
    description       = "minecraft-from-dmz"
    destination       = "192.168.1.0/24" # App
    # destination_type  = "CIDR_BLOCK" # Optional on Ingress
    source            = "192.168.0.0/24" # DMZ
    tcp_options {
        destination_port_range {
            min = "25577"
            max = "25577"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "minecraft_from_public" {
    # Required
    network_security_group_id = oci_core_network_security_group.minecraft_dmz.id
    direction         = "INGRESS"
    protocol          = "6"
    # Optional
    description       = "minecraft-from-public"
    destination       = "192.168.0.0/24" # DMZ
    # destination_type  = "CIDR_BLOCK" # Optional on Ingress
    source            = "0.0.0.0/0" # Public
    tcp_options {
        destination_port_range {
        min = "25565"
        max = "25565"
        }
    }
}