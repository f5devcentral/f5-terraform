# TAGS
variable environment    { default = "f5env"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      }
variable costcenter     { default = "f5costcenter" }  

# NETWORK

variable subnet_management_cidr_block   { default = "10.0.0.0/24" }
variable subnet_public_cidr_block       { default = "10.0.1.0/24" }
variable subnet_private_cidr_block      { default = "10.0.2.0/24" }
variable subnet_application_cidr_block  { default = "10.0.3.0/24" }

variable external_gateway_id {}


# NOTE: Get creds from environment variables
provider "openstack" {
}

resource "openstack_networking_network_v2" "network_management" {
  name           = "${var.environment}-network-management"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_management" {
  name       = "${var.environment}-subnet-management"
  network_id = "${openstack_networking_network_v2.network_management.id}"
  cidr       = "${var.subnet_management_cidr_block}"
  ip_version = 4
}

resource "openstack_networking_network_v2" "network_public" {
  name           = "${var.environment}-network-public"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_public" {
  name       = "${var.environment}-subnet-public"
  network_id = "${openstack_networking_network_v2.network_public.id}"
  cidr       = "${var.subnet_public_cidr_block}"
  ip_version = 4
}


resource "openstack_networking_network_v2" "network_private" {
  name           = "${var.environment}-network-private"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_private" {
  name       = "${var.environment}-subnet-private"
  network_id = "${openstack_networking_network_v2.network_private.id}"
  cidr       = "${var.subnet_private_cidr_block}"
  ip_version = 4
}

resource "openstack_networking_network_v2" "network_application" {
  name           = "${var.environment}-network-application"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_application" {
  name       = "${var.environment}-subnet-application"
  network_id = "${openstack_networking_network_v2.network_application.id}"
  cidr       = "${var.subnet_application_cidr_block}"
  ip_version = 4
}


resource "openstack_networking_router_v2" "router_1" {
  name             = "${var.environment}-router"
  external_gateway = "${var.external_gateway_id}"
  admin_state_up = "true"
}


resource "openstack_networking_router_interface_v2" "router_interface_2" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_management.id}"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_public.id}"
}


output "network_management_id" { value = "${openstack_networking_network_v2.network_management.id}"}
output "subnet_management_id" { value = "${openstack_networking_subnet_v2.subnet_management.id}"}

output "network_public_id" { value = "${openstack_networking_network_v2.network_public.id}"}
output "subnet_public_id" { value = "${openstack_networking_subnet_v2.subnet_public.id}"}

output "network_private_id" { value = "${openstack_networking_network_v2.network_private.id}"}
output "subnet_private_id" { value = "${openstack_networking_subnet_v2.subnet_private.id}"}

output "network_application_id" { value = "${openstack_networking_network_v2.network_application.id}"}
output "subnet_application_id" { value = "${openstack_networking_subnet_v2.subnet_application.id}"}

