# GLOBAL
variable deployment_name  { default = "demo" }

# TAGS
variable application_dns  { default = "www.example.com" }  # ex. "www.example.com"
variable application      { default = "www"             }  # ex. "www" - short name used in object naming
variable environment      { default = "f5env"           }  # ex. dev/staging/prod
variable owner            { default = "f5owner"         }  
variable group            { default = "f5group"         }
variable costcenter       { default = "f5costcenter"    }  
variable purpose          { default = "public"          } 


# SECURITY / KEYS
variable public_ssh_key_path {}
variable ssh_key_name        {}

# WARNING: Passwords are used in Azure VMs & BIG-IPs
# Must adhere to 
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq
# https://support.f5.com/csp/article/K2873
# Additionally, as we leverage some shell scripts, must also not contain a few bash special character "$" or spaces. 
variable admin_username { default = "custom-admin" }
variable admin_password {}  

# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }


# SYSTEM
variable dns_server     { default = "8.8.8.8" }
variable ntp_server     { default = "0.us.pool.ntp.org" }
variable timezone       { default = "UTC" }


### NETWORK #### 
variable vnet_cidr_block           { default = "10.0.0.0/16" }

variable a_management_cidr_block   { default = "10.0.0.0/24" }
variable a_public_cidr_block       { default = "10.0.1.0/24" }
variable a_private_cidr_block      { default = "10.0.2.0/24" }
variable a_application_cidr_block  { default = "10.0.3.0/24" }

variable b_management_cidr_block   { default = "10.0.10.0/24" }
variable b_public_cidr_block       { default = "10.0.11.0/24" }
variable b_private_cidr_block      { default = "10.0.12.0/24" }
variable b_application_cidr_block  { default = "10.0.13.0/24" }

variable restricted_src_address    { default = "0.0.0.0/0" }

#### APPLICATION #### 

variable docker_image       { default = "f5devcentral/f5-demo-app:lates"  }
variable aws_docker_image   { default = "f5devcentral/f5-demo-app:AWS"    }
variable azure_docker_image { default = "f5devcentral/f5-demo-app:azure"  }
variable gce_docker_image   { default = "f5devcentral/f5-demo-app:google" }


# AUTO SCALE
variable app_scale_min                    { default = 1 }
variable app_scale_max                    { default = 3 }
variable app_scale_desired                { default = 2 }
variable app_scale_down_bytes_threshold   { default = "10000" }
variable app_scale_up_bytes_threshold     { default = "35000" }
variable app_notification_email           { default = "user@example.com" }


#### PROXY #### 

# SERVICE
variable vs_dns_name           { default = "www.example.com" }
variable vs_port               { default = "443"}
variable pool_member_address   { default = "10.0.3.4" }
variable pool_member_port      { default = "80" }
variable pool_name             { default = "www.example.com" }  # Either DNS or Autoscale Group Name, No spaces allowed
variable pool_tag_key          { default = "Name" }
variable pool_tag_value        { default = "dev-www-instance" }

# NOTE: If you don't configure these, Service Discovery iApp will deploy but just not work
variable pool_azure_resource_group   { default = "none" }
variable pool_azure_subscription_id  { default = "none" }
variable pool_azure_tenant_id        { default = "none" }
variable pool_azure_client_id        { default = "none" }
variable pool_azure_sp_secret        { default = "none" }


######## PROVIDER SPECIFIC #######

### PLACEMENT
# AWS
variable aws_region                 { default = "us-west-2" }
variable aws_az1                    { default = "us-west-2a" }
variable aws_az2                    { default = "us-west-2b" }
variable aws_availability_zones     { default = "us-west-2a,us-west-2b" }

# AZURE
variable azure_region               { default = "West US" } 
variable azure_location             { default = "westus"  }        

# GCE
variable gce_region                 { default = "us-west1"   } 
variable gce_zone                   { default = "us-west1-a" } 

##### NETWORK

variable vnet_azure_resource_group  { default = "network.example.com" }


##### APP:
variable app_aws_instance_type      { default = "t2.small" }
variable app_aws_amis {     
    type = "map" 
    default = {
        "ap-northeast-1" = "ami-c9e3c0ae"
        "ap-northeast-2" = "ami-3cda0852"
        "ap-southeast-1" = "ami-6e74ca0d"
        "ap-southeast-2" = "ami-92e8e6f1"
        "eu-central-1" = "ami-1b4d9e74"
        "eu-west-1" = "ami-b5a893d3"
        "sa-east-1" = "ami-36187a5a"
        "us-east-1" = "ami-e4139df2"
        "us-east-2" = "ami-33ab8f56"
        "us-west-1" = "ami-30476250"
        "us-west-2" = "ami-17ba2a77"
    }
}


variable app_azure_resource_group   { default = "app.example.com" }
variable app_azure_instance_type    { default = "Standard_A0" }
variable app_instance_name_prefix   { default = "appvm" }

variable app_gce_instance_type      { default = "n1-standard-1" }

### PROXY 
variable proxy_aws_instance_type    { default = "m4.2xlarge" }
variable proxy_aws_amis {
    type = "map" 
    default = {
        "ap-northeast-1" = "ami-eb1d2c8c"
        "ap-northeast-2" = "ami-dcdf02b2"
        "ap-southeast-1" = "ami-9b08b2f8"
        "ap-southeast-2" = "ami-67d8d304"
        "eu-central-1"   = "ami-c74e91a8"
        "eu-west-1"      = "ami-e56d4b85"
        "sa-east-1"      = "ami-7d8ee211"
        "us-east-1"      = "ami-4c76185a"
        "us-east-2"      = "ami-2be6c14e"
        "us-west-1"      = "ami-e56d4b85"
        "us-west-2"      = "ami-a4bc27c4"
    }
}

variable proxy_azure_resource_group { default = "proxy.example.com" }
variable proxy_azure_instance_type  { default = "Standard_D3_v2" }
variable proxy_azure_image_name     { default = "f5-bigip-virtual-edition-25m-best-byol" }

# Application
variable proxy_gce_instance_type    { default = "n1-standard-4" }

# LICENSE
variable aws_proxy_license_key_1     {}
variable azure_proxy_license_key_1   {}
variable gce_proxy_license_key_1     {}



###### RESOURCES

# NOTE: Get creds from environment variables
provider "aws" {
  region = "${var.aws_region}"
}

#A key pair is used to control login access to EC2 instances
resource "aws_key_pair" "auth" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${file(var.public_ssh_key_path)}"
}

provider "azurerm" {
}

provider "google" {
    region = "${var.gce_region}"
}


module "network" {
    source         = "./infrastructure/network"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    vnet_cidr_block           = "${var.vnet_cidr_block}"
    a_management_cidr_block   = "${var.a_management_cidr_block}"
    a_public_cidr_block       = "${var.a_public_cidr_block}"
    a_private_cidr_block      = "${var.a_private_cidr_block}"
    a_application_cidr_block  = "${var.a_application_cidr_block}"
    b_management_cidr_block   = "${var.b_management_cidr_block}"
    b_public_cidr_block       = "${var.b_public_cidr_block}"
    b_private_cidr_block      = "${var.b_private_cidr_block}"
    b_application_cidr_block  = "${var.b_application_cidr_block}"
    aws_region                = "${var.aws_region}"
    aws_az1                   = "${var.aws_az1}"
    aws_az2                   = "${var.aws_az2}"
    azure_region              = "${var.azure_region}"
    azure_resource_group      = "${var.vnet_azure_resource_group}"
    gce_region                = "${var.gce_region}"
}

### AWS
output "aws_vpc_id" { value = "${module.network.aws_vpc_id}" }

output "aws_igw_id" { value = "${module.network.aws_igw_id}" }

output "aws_az_a_nat_gateway_id" { value = "${module.network.aws_az_a_nat_gateway_id}" }
output "aws_az_a_nat_gateway_ip" { value = "${module.network.aws_az_a_nat_gateway_ip}" }
output "aws_az_b_nat_gateway_id" { value = "${module.network.aws_az_b_nat_gateway_id}" }
output "aws_az_b_nat_gateway_ip" { value = "${module.network.aws_az_b_nat_gateway_ip}" }

output "aws_public_routing_table_id" { value = "${module.network.aws_public_routing_table_id}" }

output "aws_private_routing_table_a_id" { value = "${module.network.aws_private_routing_table_a_id}" }
output "aws_private_routing_table_b_id" { value = "${module.network.aws_private_routing_table_b_id}" }
output "aws_management_routing_table_a_id" { value = "${module.network.aws_management_routing_table_a_id}" }
output "aws_management_routing_table_b_id" { value = "${module.network.aws_management_routing_table_b_id}" }
output "aws_application_routing_table_a_id" { value = "${module.network.aws_application_routing_table_a_id}" }
output "aws_application_routing_table_b_id" { value = "${module.network.aws_application_routing_table_b_id}" }

output "aws_subnet_management_a_id" { value = "${module.network.aws_subnet_management_a_id}" }
output "aws_subnet_management_b_id" { value = "${module.network.aws_subnet_management_b_id}" }
output "aws_subnet_public_a_id" { value = "${module.network.aws_subnet_public_a_id}" }
output "aws_subnet_public_b_id" { value = "${module.network.aws_subnet_public_b_id}" }
output "aws_subnet_private_a_id" { value = "${module.network.aws_subnet_private_a_id}" }
output "aws_subnet_private_b_id" { value = "${module.network.aws_subnet_private_b_id}" }
output "aws_subnet_application_a_id" { value = "${module.network.aws_subnet_application_a_id}" }
output "aws_subnet_application_b_id" { value = "${module.network.aws_subnet_application_b_id}" }

output "aws_management_subnet_ids" { value = "${module.network.aws_management_subnet_ids}" }
output "aws_public_subnet_ids" { value = "${module.network.aws_public_subnet_ids}" }
output "aws_private_subnet_ids" { value = "${module.network.aws_private_subnet_ids}" }
output "aws_application_subnet_ids" { value = "${module.network.aws_application_subnet_ids}" }


### AZURE
output "azure_virtual_network_id" { value = "${module.network.azure_virtual_network_id}" }

output "azure_subnet_management_id" { value = "${module.network.azure_subnet_management_id}" }
output "azure_subnet_public_id" { value = "${module.network.azure_subnet_public_id}" }
output "azure_subnet_private_id" { value = "${module.network.azure_subnet_private_id}" }
output "azure_subnet_application_id" { value = "${module.network.azure_subnet_application_id}" }

### GCE

output "gce_network"            { value = "${module.network.gce_network}"  }
output "gce_subnet_management"  { value = "${module.network.gce_subnet_management}"  }
output "gce_subnet_public"      { value = "${module.network.gce_subnet_public}"  }
output "gce_subnet_private"     { value = "${module.network.gce_subnet_private}"  }
output "gce_subnet_application" { value = "${module.network.gce_subnet_application}"  }


module "app" {
    source          = "./application"
    application_dns = "${var.application_dns}"
    application     = "${var.application}"
    environment     = "${var.environment}"
    owner           = "${var.owner}"
    group           = "${var.group}"
    costcenter      = "${var.costcenter}"
    purpose         = "${var.purpose}"
    admin_username              = "${var.admin_username}"
    admin_password              = "${var.admin_password}"
    ssh_key_name                = "${var.ssh_key_name}"
    ssh_key_public              = "${file("${var.public_ssh_key_path}")}"
    aws_docker_image            = "${var.aws_docker_image}"
    aws_region                  = "${var.aws_region}"
    aws_vpc_id                  = "${module.network.aws_vpc_id}"
    aws_availability_zones      = "${var.aws_availability_zones}"
    aws_subnet_ids              = "${module.network.aws_application_subnet_ids}"
    aws_instance_type           = "${var.app_aws_instance_type}"
    aws_amis                    = "${var.app_aws_amis}"
    azure_region                = "${var.azure_region}"
    azure_resource_group        = "${var.app_azure_resource_group}"
    azure_vnet_id               = "${module.network.azure_virtual_network_id}"
    azure_vnet_resource_group   = "${var.vnet_azure_resource_group}"
    azure_subnet_id             = "${module.network.azure_subnet_application_id}"
    azure_instance_type         = "${var.app_azure_instance_type}"
    gce_region                  = "${var.gce_region}"
    gce_zone                    = "${var.gce_zone}"
    gce_network                 = "${module.network.gce_network}"
    gce_subnet_id               = "${module.network.gce_subnet_application}"
    gce_instance_type           = "${var.app_gce_instance_type}"
}

### AWS
output "app_aws_sg_id" { value = "${module.app.aws_sg_id}" }
output "app_aws_sg_name" { value = "${module.app.aws_sg_name}" }

output "app_aws_asg_id" { value = "${module.app.aws_asg_id}" }
output "app_aws_asg_name" { value = "${module.app.aws_asg_name}" }

### AZURE
output "app_azure_sg_id" { value = "${module.app.azure_sg_id}" }
output "app_azure_sg_name" { value = "${module.app.azure_sg_name}" }

output "app_azure_lb_id" { value = "${module.app.azure_lb_id}" }
output "app_azure_lb_private_ip" { value = "${module.app.azure_lb_private_ip}" }
output "app_azure_lb_public_ip" { value = "${module.app.azure_lb_public_ip}" }

### GCE
output "app_gce_sg_id" { value = "${module.app.gce_sg_id}" }
output "app_gce_lb_public_ip" { value = "${module.app.gce_lb_public_ip}" }


module "proxy" {
    source          = "./infrastructure/proxy"
    application_dns = "${var.application_dns}"
    application     = "${var.application}"
    environment     = "${var.environment}"
    owner           = "${var.owner}"
    group           = "${var.group}"
    costcenter      = "${var.costcenter}"
    purpose         = "${var.purpose}"
    admin_username              = "${var.admin_username}"
    admin_password              = "${var.admin_password}"
    ssh_key_name                = "${var.ssh_key_name}"
    ssh_key_public              = "${file("${var.public_ssh_key_path}")}"
    site_ssl_cert               = "${file("${var.site_ssl_cert}")}"
    site_ssl_key                = "${file("${var.site_ssl_key}")}"
    aws_region                  = "${var.aws_region}"
    aws_availability_zone       = "${var.aws_az1}"
    aws_vpc_id                  = "${module.network.aws_vpc_id}"
    aws_subnet_id               = "${module.network.aws_subnet_public_a_id}"
    aws_instance_type           = "${var.proxy_aws_instance_type}"
    aws_amis                    = "${var.proxy_aws_amis}"
    azure_region                = "${var.azure_region}"
    azure_resource_group        = "${var.proxy_azure_resource_group}"
    azure_vnet_id               = "${module.network.azure_virtual_network_id}"
    azure_vnet_resource_group   = "${var.vnet_azure_resource_group}"
    azure_subnet_id             = "${module.network.azure_subnet_public_id}"
    azure_instance_type         = "${var.proxy_azure_instance_type}"
    pool_azure_resource_group   = "${var.pool_azure_resource_group}"
    pool_azure_subscription_id  = "${var.pool_azure_subscription_id}"
    pool_azure_tenant_id        = "${var.pool_azure_tenant_id }"
    pool_azure_client_id        = "${var.pool_azure_client_id}"
    pool_azure_sp_secret        = "${var.pool_azure_sp_secret}"  
    gce_region                  = "${var.gce_region}"
    gce_zone                    = "${var.gce_zone}"
    gce_network                 = "${module.network.gce_network}"
    gce_subnet_id               = "${module.network.gce_subnet_public}"
    gce_instance_type           = "${var.proxy_gce_instance_type}"
    pool_address                = "${module.app.gce_lb_public_ip}"
    aws_proxy_license_key_1     = "${var.aws_proxy_license_key_1}"
    azure_proxy_license_key_1   = "${var.azure_proxy_license_key_1}"
    gce_proxy_license_key_1     = "${var.gce_proxy_license_key_1}"
}

### AWS
output "proxy_aws_sg_id" { value = "${module.proxy.aws_sg_id}" }
output "proxy_aws_sg_name" { value = "${module.proxy.aws_sg_name}" }

output "proxy_aws_instance_id" { value = "${module.proxy.aws_instance_id}"  }
output "proxy_aws_instance_private_ip" { value = "${module.proxy.aws_instance_private_ip}" }
output "proxy_aws_instance_public_ip" { value = "${module.proxy.aws_instance_public_ip}" }

### AZURE
output "proxy_azure_sg_id" { value = "${module.proxy.azure_sg_id}" }
output "proxy_azure_sg_name" { value = "${module.proxy.azure_sg_name}" }

output "proxy_azure_instance_id" { value = "${module.proxy.azure_instance_id}"  }
output "proxy_azure_instance_private_ip" { value = "${module.proxy.azure_instance_private_ip}" }
output "proxy_azure_instance_public_ip" { value = "${module.proxy.azure_instance_public_ip}" }

### GCE
output "proxy_gce_sg_id" { value = "${module.proxy.gce_sg_id}" }

output "proxy_gce_instance_id" { value = "${module.proxy.gce_instance_id}"  }
output "proxy_gce_instance_private_ip" { value = "${module.proxy.gce_instance_private_ip}" }
output "proxy_gce_instance_public_ip" { value = "${module.proxy.gce_instance_public_ip}" }



output "www_public_ips" { value = "${module.proxy.aws_instance_public_ip},${module.proxy.azure_instance_public_ip},${module.proxy.gce_instance_public_ip}" } 
