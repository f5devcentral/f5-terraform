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

variable b_management_cidr_block   { default = "10.0.10.0/24" }
variable b_public_cidr_block       { default = "10.0.11.0/24" }
variable b_private_cidr_block      { default = "10.0.12.0/24" }
variable b_application_cidr_block  { default = "10.0.13.0/24" }


#### APPLICATION #### 

variable docker_image       { default = "f5devcentral/f5-demo-app:latest"  }
variable aws_docker_image   { default = "f5devcentral/f5-demo-app:AWS"    }

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

### PLACEMENT
# AWS
variable aws_region                 { default = "us-west-2" }
variable aws_az1                    { default = "us-west-2a" }
variable aws_az2                    { default = "us-west-2b" }
variable aws_availability_zones     { default = "us-west-2a,us-west-2b" }
    

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

##### PROXY
variable proxy_aws_instance_type    { default = "m4.2xlarge" }
variable proxy_aws_amis { 
    type = "map" 
    default = {
        "ap-northeast-1" = "ami-3b1e2f5c"
        "ap-northeast-2" = "ami-e0dc018e"
        "ap-southeast-1" = "ami-530eb430"
        "ap-southeast-2" = "ami-60d8d303"
        "eu-central-1"   = "ami-c24e91ad"
        "eu-west-1"      = "ami-1fbdb079"
        "sa-east-1"      = "ami-d58de1b9"
        "us-east-1"      = "ami-09721c1f"
        "us-east-2"      = "ami-3c183f59"
        "us-west-1"      = "ami-c46f49a4"
        "us-west-2"      = "ami-6bbd260b"
    }
}


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


module "aws_network"{
    source         = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/network?ref=v0.0.9"
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



module "aws_app" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/aws/application?ref=v0.0.9"
  docker_image            = "${var.aws_docker_image}"
  application_dns         = "${var.application_dns}"
  application             = "${var.application}"
  environment             = "${var.environment}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  purpose                 = "${var.purpose}"
  region                  = "${var.aws_region}"
  vpc_id                  = "${module.aws_network.vpc_id}"
  availability_zones      = "${var.aws_availability_zones}"
  subnet_ids              = "${module.aws_network.application_subnet_ids}"
  amis                    = "${var.app_aws_amis}"
  instance_type           = "${var.app_aws_instance_type}"
  ssh_key_name            = "${var.ssh_key_name}"
  restricted_src_address  = "${var.restricted_src_address}"
}

output "app_aws_sg_id" { value = "${module.aws_app.sg_id}" }
output "app_aws_sg_name" { value = "${module.aws_app.sg_name}" }

output "app_aws_asg_id" { value = "${module.aws_app.asg_id}" }
output "app_aws_asg_name" { value = "${module.aws_app.asg_name}" }


module "aws_proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/proxy/standalone/1nic/util?ref=v0.0.9"
  purpose         = "${var.purpose}"
  environment     = "${var.environment}"
  application     = "${var.application}"
  owner           = "${var.owner}"
  group           = "${var.group}"
  costcenter      = "${var.costcenter}"
  region          = "${var.aws_region}"
  vpc_id                  = "${module.aws_network.vpc_id}"
  availability_zone       = "${var.aws_az1}"
  subnet_id               = "${module.aws_network.subnet_public_a_id}"
  restricted_src_address  = "${var.restricted_src_address}"
  amis                    = "${var.proxy_aws_amis}"
  instance_type           = "${var.proxy_aws_instance_type}"
  ssh_key_name            = "${var.ssh_key_name}"
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
}

output "proxy_aws_sg_id" { value = "${module.aws_proxy.sg_id}" }
output "proxy_aws_sg_name" { value = "${module.aws_proxy.sg_name}" }

output "proxy_aws_instance_id" { value = "${module.aws_proxy.instance_id}"  }
output "proxy_aws_instance_private_ip" { value = "${module.aws_proxy.instance_private_ip}" }
output "proxy_aws_instance_public_ip" { value = "${module.aws_proxy.instance_public_ip}" }


