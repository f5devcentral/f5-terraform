# TAGS
variable environment    { default = "f5env"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      }
variable costcenter     { default = "f5costcenter" }  

variable "region" { default = "us-west-2" }

variable "vpc_cidr_block"                   { default = "10.0.0.0/16" }

variable "subnet_a_management_cidr_block"   { default = "10.0.0.0/24" }
variable "subnet_a_public_cidr_block"       { default = "10.0.1.0/24" }
variable "subnet_a_private_cidr_block"      { default = "10.0.2.0/24" }
variable "subnet_a_application_cidr_block"  { default = "10.0.3.0/24" }

variable "subnet_b_management_cidr_block"   { default = "10.0.10.0/24" }
variable "subnet_b_public_cidr_block"       { default = "10.0.11.0/24" }
variable "subnet_b_private_cidr_block"      { default = "10.0.12.0/24" }
variable "subnet_b_application_cidr_block"  { default = "10.0.13.0/24" }

variable "az1" { default = "us-west-2a" }
variable "az2" { default = "us-west-2b" }


# NOTE: Get creds from environment variables
provider "aws" {
  region = "${var.region}"
}

module "vpc"{
  source        = "./vpc"
  cidr_block     = "${var.vpc_cidr_block}"
  environment    = "${var.environment}"
  owner          = "${var.owner}"
  group          = "${var.group}"
  costcenter     = "${var.costcenter}"
}


module "igw"{
  source         = "./internet_gateway"
  vpc_id         = "${module.vpc.vpc_id}"
  environment    = "${var.environment}"
  owner          = "${var.owner}"
  group          = "${var.group}"
  costcenter     = "${var.costcenter}"
}

module "az_a_nat_gateway"{
  source       = "./nat_gateway"
  subnet_id    = "${module.subnet_public_a.public_subnet_id}"
}

module "az_b_nat_gateway"{
  source       = "./nat_gateway"
  subnet_id = "${module.subnet_public_b.public_subnet_id}"
}


#create subnets in two different availability zones

module "subnet_management_a" {
  source            = "./subnet_management"
  cidr_block        = "${var.subnet_a_management_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az1}"
  route_table_id    = "${module.az_a_management_route.management_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "subnet_management_b" {
  source            = "./subnet_management"
  cidr_block        = "${var.subnet_b_management_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az2}"
  route_table_id    = "${module.az_b_management_route.management_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "subnet_public_a" {
  source            = "./subnet_public"
  cidr_block        = "${var.subnet_a_public_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az1}"
  route_table_id    = "${module.public_route.public_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}


module "subnet_public_b" {
  source            = "./subnet_public"
  cidr_block        = "${var.subnet_b_public_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az2}"
  route_table_id    = "${module.public_route.public_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}


module "subnet_private_a" {
  source            = "./subnet_private"
  cidr_block        = "${var.subnet_a_private_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az1}"
  route_table_id    = "${module.az_a_private_route.private_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "subnet_private_b" {
  source            = "./subnet_private"
  cidr_block        = "${var.subnet_b_private_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az2}"
  route_table_id    = "${module.az_b_private_route.private_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "subnet_application_a" {
  source            = "./subnet_application"
  cidr_block        = "${var.subnet_a_application_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az1}"
  route_table_id    = "${module.az_a_application_route.application_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "subnet_application_b" {
  source            = "./subnet_application"
  cidr_block        = "${var.subnet_b_application_cidr_block}"
  vpc_id            = "${module.vpc.vpc_id}"
  availability_zone = "${var.az2}"
  route_table_id    = "${module.az_b_application_route.application_route_table_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}


module "public_route" {
  source            = "./routing_table_public"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "0.0.0.0/0"
  gateway_id        = "${module.igw.igw_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "az_a_management_route" {
  source            = "./routing_table_management"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "0.0.0.0/0"
  nat_gateway_id    = "${module.az_a_nat_gateway.nat_gateway_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "az_b_management_route" {
  source            = "./routing_table_management"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "0.0.0.0/0"
  nat_gateway_id    = "${module.az_b_nat_gateway.nat_gateway_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}


module "az_a_private_route" {
  source            = "./routing_table_private"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "0.0.0.0/0"
  nat_gateway_id    = "${module.az_a_nat_gateway.nat_gateway_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}


module "az_b_private_route" {
  source            = "./routing_table_private"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "0.0.0.0/0"
  nat_gateway_id    = "${module.az_b_nat_gateway.nat_gateway_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}


module "az_a_application_route" {
  source            = "./routing_table_application"
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "0.0.0.0/0"
  nat_gateway_id    = "${module.az_a_nat_gateway.nat_gateway_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}

module "az_b_application_route" {
  source            = "./routing_table_application"
  vpc_id         = "${module.vpc.vpc_id}"
  cidr_block     = "0.0.0.0/0"
  nat_gateway_id = "${module.az_b_nat_gateway.nat_gateway_id}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
}


# outputs produced at the end of a terraform applicationly: id of VPC, internet gateway
# NAT gateways, routing tables & subnets
output "vpc_id" { value = "${module.vpc.vpc_id}" }

output "igw_id" { value = "${module.igw.igw_id}" }

output "az_a_nat_gateway_id" { value = "${module.az_a_nat_gateway.nat_gateway_id}" }
output "az_a_nat_gateway_ip" { value = "${module.az_a_nat_gateway.nat_gateway_ip}" }
output "az_b_nat_gateway_id" { value = "${module.az_b_nat_gateway.nat_gateway_id}" }
output "az_b_nat_gateway_ip" { value = "${module.az_b_nat_gateway.nat_gateway_ip}" }


output "public_routing_table_id" { value = "${module.public_route.public_route_table_id}" }

output "private_routing_table_a_id" { value = "${module.az_a_private_route.private_route_table_id}" }
output "private_routing_table_b_id" { value = "${module.az_b_private_route.private_route_table_id}" }
output "management_routing_table_a_id" { value = "${module.az_a_management_route.management_route_table_id}" }
output "management_routing_table_b_id" { value = "${module.az_b_management_route.management_route_table_id}" }
output "application_routing_table_a_id" { value = "${module.az_a_application_route.application_route_table_id}" }
output "application_routing_table_b_id" { value = "${module.az_b_application_route.application_route_table_id}" }

output "subnet_management_a_id" { value = "${module.subnet_management_a.management_subnet_id}" }
output "subnet_management_b_id" { value = "${module.subnet_management_b.management_subnet_id}" }
output "subnet_public_a_id" { value = "${module.subnet_public_a.public_subnet_id}" }
output "subnet_public_b_id" { value = "${module.subnet_public_b.public_subnet_id}" }
output "subnet_private_a_id" { value = "${module.subnet_private_a.private_subnet_id}" }
output "subnet_private_b_id" { value = "${module.subnet_private_b.private_subnet_id}" }
output "subnet_application_a_id" { value = "${module.subnet_application_a.application_subnet_id}" }
output "subnet_application_b_id" { value = "${module.subnet_application_b.application_subnet_id}" }

output "management_subnet_ids" { value = "${module.subnet_management_a.management_subnet_id},${module.subnet_management_b.management_subnet_id}" }
output "public_subnet_ids" { value = "${module.subnet_public_a.public_subnet_id},${module.subnet_public_b.public_subnet_id}" }
output "private_subnet_ids" { value = "${module.subnet_private_a.private_subnet_id},${module.subnet_private_b.private_subnet_id}" }
output "application_subnet_ids" { value = "${module.subnet_application_a.application_subnet_id},${module.subnet_application_b.application_subnet_id}" }

