### VARIABLES

# TAGS
variable application_dns  { default = "www.example.com" }  # ex. "www.example.com"
variable application      { default = "www"             }  # ex. "www" - short name used in object naming
variable environment      { default = "f5env"           }  # ex. dev/staging/prod
variable owner            { default = "f5owner"         }  
variable group            { default = "f5group"         }
variable costcenter       { default = "f5costcenter"    }  
variable purpose          { default = "public"          } 

variable vnet_cidr_block           { default = "10.0.0.0/16" }

variable a_management_cidr_block   { default = "10.0.0.0/24" }
variable a_public_cidr_block       { default = "10.0.1.0/24" }
variable a_private_cidr_block      { default = "10.0.2.0/24" }
variable a_application_cidr_block  { default = "10.0.3.0/24" }

variable b_management_cidr_block   { default = "10.0.10.0/24" }
variable b_public_cidr_block       { default = "10.0.11.0/24" }
variable b_private_cidr_block      { default = "10.0.12.0/24" }
variable b_application_cidr_block  { default = "10.0.13.0/24" }

# AWS
variable aws_region             { default = "us-west-2" }
variable aws_az1                { default = "us-west-2a" }
variable aws_az2                { default = "us-west-2b" }

# AZURE
variable azure_region           { default = "West US" } 
variable azure_resource_group   { default = "network.example.com" }

# GCE
variable gce_region             { default = "us-west1" } 


# RESOURCES

# NOTE: Get creds from environment variables
provider "aws" {
  region = "${var.aws_region}"
}

module "aws_network"{
    source         = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/network?ref=v0.0.6"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    region                           = "${var.aws_region}"
    vpc_cidr_block                   = "${var.vnet_cidr_block}"
    subnet_a_management_cidr_block   = "${var.a_management_cidr_block}"
    subnet_a_public_cidr_block       = "${var.a_public_cidr_block}"
    subnet_a_private_cidr_block      = "${var.a_private_cidr_block}"
    subnet_a_application_cidr_block  = "${var.a_application_cidr_block}"
    subnet_b_management_cidr_block   = "${var.b_management_cidr_block}"
    subnet_b_public_cidr_block       = "${var.b_public_cidr_block}"
    subnet_b_private_cidr_block      = "${var.b_private_cidr_block}"
    subnet_b_application_cidr_block  = "${var.b_application_cidr_block}"
    az1 = "${var.aws_az1}"
    az2 = "${var.aws_az2}"
}

# outputs produced at the end of a terraform applicationly: id of VPC, internet gateway
# NAT gateways, routing tables & subnets
output "aws_vpc_id" { value = "${module.aws_network.vpc_id}" }

output "aws_igw_id" { value = "${module.aws_network.igw_id}" }

output "aws_az_a_nat_gateway_id" { value = "${module.aws_network.az_a_nat_gateway_id}" }
output "aws_az_a_nat_gateway_ip" { value = "${module.aws_network.az_a_nat_gateway_ip}" }
output "aws_az_b_nat_gateway_id" { value = "${module.aws_network.az_b_nat_gateway_id}" }
output "aws_az_b_nat_gateway_ip" { value = "${module.aws_network.az_b_nat_gateway_ip}" }

output "aws_public_routing_table_id" { value = "${module.aws_network.public_routing_table_id}" }

output "aws_private_routing_table_a_id" { value = "${module.aws_network.private_routing_table_a_id}" }
output "aws_private_routing_table_b_id" { value = "${module.aws_network.private_routing_table_b_id}" }
output "aws_management_routing_table_a_id" { value = "${module.aws_network.management_routing_table_a_id}" }
output "aws_management_routing_table_b_id" { value = "${module.aws_network.management_routing_table_b_id}" }
output "aws_application_routing_table_a_id" { value = "${module.aws_network.application_routing_table_a_id}" }
output "aws_application_routing_table_b_id" { value = "${module.aws_network.application_routing_table_b_id}" }

output "aws_subnet_management_a_id" { value = "${module.aws_network.subnet_management_a_id}" }
output "aws_subnet_management_b_id" { value = "${module.aws_network.subnet_management_b_id}" }
output "aws_subnet_public_a_id" { value = "${module.aws_network.subnet_public_a_id}" }
output "aws_subnet_public_b_id" { value = "${module.aws_network.subnet_public_b_id}" }
output "aws_subnet_private_a_id" { value = "${module.aws_network.subnet_private_a_id}" }
output "aws_subnet_private_b_id" { value = "${module.aws_network.subnet_private_b_id}" }
output "aws_subnet_application_a_id" { value = "${module.aws_network.subnet_application_a_id}" }
output "aws_subnet_application_b_id" { value = "${module.aws_network.subnet_application_b_id}" }

output "aws_management_subnet_ids" { value = "${module.aws_network.management_subnet_ids}" }
output "aws_public_subnet_ids" { value = "${module.aws_network.public_subnet_ids}" }
output "aws_private_subnet_ids" { value = "${module.aws_network.private_subnet_ids}" }
output "aws_application_subnet_ids" { value = "${module.aws_network.application_subnet_ids}" }


# NOTE: Get creds from environment variables
provider "azurerm" {
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.azure_resource_group}"
  location = "${var.azure_region}"

  tags {
    environment = "${var.environment}-${var.azure_resource_group}"
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "Address Eventual Consistent APIs: Re: Status=404 Code=ResourceGroupNotFound"
      echo "See https://github.com/hashicorp/terraform/issues/2499"
      echo "https://github.com/hashicorp/terraform/issues/14970"
      sleep 10
EOF

  }

}

module "azure_network" {
    source         = "github.com/f5devcentral/f5-terraform//modules/providers/azure/infrastructure/network?ref=v0.0.6"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    region                         = "${var.azure_region}" 
    resource_group                 = "${azurerm_resource_group.resource_group.name}"
    vnet_cidr_block                = "${var.vnet_cidr_block}"
    subnet_management_cidr_block   = "${var.a_management_cidr_block}"
    subnet_public_cidr_block       = "${var.a_public_cidr_block}" 
    subnet_private_cidr_block      = "${var.a_private_cidr_block}"
    subnet_application_cidr_block  = "${var.a_application_cidr_block}"
}

output "azure_virtual_network_id" { value = "${module.azure_network.virtual_network_id}" }

output "azure_subnet_management_id" { value = "${module.azure_network.subnet_management_id}" }
output "azure_subnet_public_id" { value = "${module.azure_network.subnet_public_id}" }
output "azure_subnet_private_id" { value = "${module.azure_network.subnet_private_id}" }
output "azure_subnet_application_id" { value = "${module.azure_network.subnet_application_id}" }


# NOTE: Get creds from environment variables
provider "google" {
    region = "${var.gce_region}"
}


module "gce_network" {
    source         = "github.com/f5devcentral/f5-terraform//modules/providers/gce/infrastructure/network?ref=v0.0.6"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    region                         = "${var.gce_region}" 
    subnet_management_cidr_block   = "${var.a_management_cidr_block}"
    subnet_public_cidr_block       = "${var.a_public_cidr_block}" 
    subnet_private_cidr_block      = "${var.a_private_cidr_block}"
    subnet_application_cidr_block  = "${var.a_application_cidr_block}"
}


output "gce_network"            { value = "${module.gce_network.network}"  }
output "gce_subnet_management"  { value = "${module.gce_network.subnet_management}"  }
output "gce_subnet_public"      { value = "${module.gce_network.subnet_public}"  }
output "gce_subnet_private"     { value = "${module.gce_network.subnet_private}"  }
output "gce_subnet_application" { value = "${module.gce_network.subnet_application}"  }