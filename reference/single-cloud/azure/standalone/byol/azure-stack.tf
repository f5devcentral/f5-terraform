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

# WARNING: Passwords Must adhere to 
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


#### APPLICATION #### 

variable docker_image       { default = "f5devcentral/f5-demo-app:latest"  }
variable azure_docker_image   { default = "f5devcentral/f5-demo-app:azure"    }

variable restricted_src_address { default = "0.0.0.0/0" }

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
variable pool_azure_resource_group   { default = "app.example.com" }
variable pool_azure_subscription_id  { default = "none" }
variable pool_azure_tenant_id        { default = "none" }
variable pool_azure_client_id        { default = "none" }
variable pool_azure_sp_secret        { default = "none" }



######## PROVIDER SPECIFIC #######

# AZURE
variable azure_region               { default = "West US" } 
variable azure_location             { default = "westus"  }   

##### NETWORK
variable vnet_azure_resource_group  { default = "network.example.com" }

### APP
variable app_azure_resource_group   { default = "app.example.com" }
variable app_azure_instance_type    { default = "Standard_A0" }
variable app_instance_name_prefix   { default = "appvm" }

### PROXY 
variable proxy_azure_resource_group { default = "proxy.example.com" }
variable proxy_azure_instance_type  { default = "Standard_D3_v2" }
variable proxy_azure_image_name     { default = "f5-bigip-virtual-edition-best-byol" }

# LICENSE
variable azure_proxy_license_key_1 {}


###### RESOURCES


# NOTE: Get creds from environment variables

provider "azurerm" {
}

resource "azurerm_resource_group" "network_resource_group" {
  name     = "${var.vnet_azure_resource_group}"
  location = "${var.azure_region}"

  tags {
    environment = "${var.environment}-${var.vnet_azure_resource_group}"
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
    source         = "github.com/f5devcentral/f5-terraform//modules/providers/azure/infrastructure/network?ref=v0.0.7"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    region                         = "${var.azure_region}" 
    resource_group                 = "${azurerm_resource_group.network_resource_group.name}"
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




resource "azurerm_resource_group" "app_resource_group" {
  name     = "${var.app_azure_resource_group}"
  location = "${var.azure_region}"

  tags {
    environment = "${var.environment}-${var.app_azure_resource_group}"
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


module "azure_app" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/azure/application?ref=v0.0.7"
  docker_image            = "${var.azure_docker_image}"
  application_dns         = "${var.application_dns}"
  application             = "${var.application}"
  environment             = "${var.environment}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  purpose                 = "${var.purpose}"
  region                  = "${var.azure_region}"
  resource_group          = "${azurerm_resource_group.app_resource_group.name}"
  vnet_id                 = "${module.azure_network.virtual_network_id}"
  subnet_id               = "${module.azure_network.subnet_application_id}"
  instance_type           = "${var.app_azure_instance_type}"
  instance_name_prefix    = "${var.app_instance_name_prefix}"
  ssh_key_public          = "${file("${var.public_ssh_key_path}")}"
  restricted_src_address  = "${var.restricted_src_address}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
}

output "app_azure_sg_id" { value = "${module.azure_app.sg_id}" }
output "app_azure_sg_name" { value = "${module.azure_app.sg_name}" }

output "app_azure_lb_id" { value = "${module.azure_app.lb_id}" }
output "app_azure_lb_private_ip" { value = "${module.azure_app.lb_private_ip}" }
output "app_azure_lb_public_ip" { value = "${module.azure_app.lb_public_ip}" }



resource "azurerm_resource_group" "proxy_resource_group" {
  name     = "${var.proxy_azure_resource_group}"
  location = "${var.azure_region}"

  tags {
    environment = "${var.environment}-${var.proxy_azure_resource_group}"
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

module "azure_proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/azure/infrastructure/proxy/standalone/1nic/byol?ref=v0.0.7"
  resource_group    = "${azurerm_resource_group.proxy_resource_group.name}"
  purpose           = "${var.purpose}"
  environment       = "${var.environment}"
  application       = "${var.application}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
  region                  = "${var.azure_region}"
  location                = "${var.azure_location}"
  vnet_id                 = "${module.azure_network.virtual_network_id}"
  subnet_id               = "${module.azure_network.subnet_public_id}"
  image_name              = "${var.proxy_azure_image_name}"
  instance_type           = "${var.proxy_azure_instance_type}"
  ssh_key_public          = "${file("${var.public_ssh_key_path}")}"
  restricted_src_address  = "${var.restricted_src_address}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
  site_ssl_cert           = "${var.site_ssl_cert}"
  site_ssl_key            = "${var.site_ssl_key}"
  dns_server              = "${var.dns_server}"
  ntp_server              = "${var.ntp_server}"
  timezone                = "${var.timezone}"
  vs_dns_name             = "${var.vs_dns_name}"
  vs_port                 = "${var.vs_port}"
  pool_member_port        = "${var.pool_member_port}"
  pool_name               = "${var.pool_name}"
  pool_tag_key            = "${var.pool_tag_key}"
  pool_tag_value          = "${var.pool_tag_value}"
  azure_subscription_id   = "${var.pool_azure_subscription_id}"
  azure_tenant_id         = "${var.pool_azure_tenant_id }"
  azure_resource_group    = "${var.pool_azure_resource_group}"
  azure_client_id         = "${var.pool_azure_client_id}"
  azure_sp_secret         = "${var.pool_azure_sp_secret}"
  license_key             = "${var.azure_proxy_license_key_1}"
}

output "proxy_azure_sg_id" { value = "${module.azure_proxy.sg_id}" }
output "proxy_azure_sg_name" { value = "${module.azure_proxy.sg_name}" }

output "proxy_azure_instance_id" { value = "${module.azure_proxy.instance_id}"  }
output "proxy_azure_instance_private_ip" { value = "${module.azure_proxy.instance_private_ip}" }
output "proxy_azure_instance_public_ip" { value = "${module.azure_proxy.instance_public_ip}" }