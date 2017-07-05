# TAGS
variable environment    { default = "f5env"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      }
variable costcenter     { default = "f5costcenter" }  

variable region             { default = "West US" } 
variable resource_group     { default = "network.example.com" }

variable vnet_cidr_block                { default = "10.0.0.0/16" }
variable subnet_management_cidr_block   { default = "10.0.0.0/24" }
variable subnet_public_cidr_block       { default = "10.0.1.0/24" } 
variable subnet_private_cidr_block      { default = "10.0.2.0/24" }
variable subnet_application_cidr_block  { default = "10.0.3.0/24" }

# NOTE: Get creds from environment variables
provider "azurerm" {
}

# create a virtual network
resource "azurerm_virtual_network" "network" {
    name = "${var.environment}-network"
    address_space = ["${var.vnet_cidr_block}"]
    location = "West US"
    resource_group_name = "${var.resource_group}"
}

# create subnets
resource "azurerm_subnet" "subnet_management" {
    name = "${var.environment}-subnet-management"
    resource_group_name = "${var.resource_group}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix = "${var.subnet_management_cidr_block}"
}

resource "azurerm_subnet" "subnet_public" {
    name = "${var.environment}-subnet-public"
    resource_group_name = "${var.resource_group}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix = "${var.subnet_public_cidr_block}"
}

resource "azurerm_subnet" "subnet_private" {
    name = "${var.environment}-subnet-private"
    resource_group_name = "${var.resource_group}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix = "${var.subnet_private_cidr_block}"
}

resource "azurerm_subnet" "subnet_application" {
    name = "${var.environment}-subnet-application"
    resource_group_name = "${var.resource_group}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix = "${var.subnet_application_cidr_block}"
}


output "virtual_network_id" { value = "${azurerm_virtual_network.network.id}" }

output "subnet_management_id" { value = "${azurerm_subnet.subnet_management.id}" }
output "subnet_public_id" { value = "${azurerm_subnet.subnet_public.id}" }
output "subnet_private_id" { value = "${azurerm_subnet.subnet_private.id}" }
output "subnet_application_id" { value = "${azurerm_subnet.subnet_application.id}" }


