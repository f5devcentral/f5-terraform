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
variable gce_docker_image   { default = "f5devcentral/f5-demo-app:google"    }

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



######## PROVIDER SPECIFIC #######


##### GCE PLACEMENT
variable gce_region         { default = "us-west1"   } 
variable gce_zone           { default = "us-west1-a" } 

# NETWORK:
variable gce_network        { default = "demo-network" }
variable gce_subnet_id      { default = "demo-public-subnet" }

# APPLICATION
variable app_gce_instance_type  { default = "n1-standard-1" }

# PROXY
variable proxy_gce_instance_type  { default ="n1-standard-4"  }
variable proxy_gce_image_name     { default = "f5-7626-networks-public/f5-byol-bigip-13-0-0-2-3-1671-best" }

# LICENSE
variable gce_proxy_license_key_1 {}


###### RESOURCES


# NOTE: Get creds from environment variables
provider "google" {
    region = "${var.gce_region}"
}


module "gce_network" {
    source         = "github.com/f5devcentral/f5-terraform//modules/providers/gce/infrastructure/network?ref=v0.0.8"
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



module "gce_app" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/gce/application?ref=v0.0.8"
  docker_image      = "${var.gce_docker_image}"
  application_dns   = "${var.application_dns}"
  application       = "${var.application}"
  environment       = "${var.environment}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
  purpose           = "${var.purpose}"
  region            = "${var.gce_region}"
  zone              = "${var.gce_zone}"
  network           = "${module.gce_network.network}"
  subnet_id         = "${module.gce_network.subnet_application}"
  instance_type     = "${var.app_gce_instance_type}"
  ssh_key_public    = "${file("${var.public_ssh_key_path}")}"
  admin_username    = "${var.admin_username}"
  admin_password    = "${var.admin_password}"
}

output "app_gce_sg_id" { value = "${module.gce_app.sg_id}" }
output "app_gce_lb_public_ip" { value = "${module.gce_app.lb_public_ip}" }


module "gce_proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/gce/infrastructure/proxy/standalone/1nic/byol?ref=v0.0.8"
  purpose         = "${var.purpose}"
  environment     = "${var.environment}"
  application     = "${var.application}"
  owner           = "${var.owner}"
  group           = "${var.group}"
  costcenter      = "${var.costcenter}"
  region                  = "${var.gce_region}"
  zone                    = "${var.gce_zone}"
  network                 = "${module.gce_network.network}"
  subnet_id               = "${module.gce_network.subnet_application}"
  restricted_src_address  = "${var.restricted_src_address}"
  image_name              = "${var.proxy_gce_image_name}"
  instance_type           = "${var.proxy_gce_instance_type}"
  ssh_key_public          = "${file("${var.public_ssh_key_path}")}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
  site_ssl_cert           = "${var.site_ssl_cert}"
  site_ssl_key            = "${var.site_ssl_key}"
  dns_server              = "${var.dns_server}"
  ntp_server              = "${var.ntp_server}"
  timezone                = "${var.timezone}"
  vs_dns_name             = "${var.vs_dns_name}"
  vs_port                 = "${var.vs_port}"
  pool_address            = "${module.gce_app.lb_public_ip}"
  pool_member_port        = "${var.pool_member_port}"
  pool_name               = "${var.pool_name}"
  license_key             = "${var.gce_proxy_license_key_1}"
}

output "proxy_gce_sg_id" { value = "${module.gce_proxy.sg_id}" }

output "proxy_gce_instance_id" { value = "${module.gce_proxy.instance_id}"  }
output "proxy_gce_instance_private_ip" { value = "${module.gce_proxy.instance_private_ip}" }
output "proxy_gce_instance_public_ip" { value = "${module.gce_proxy.instance_public_ip}" }

