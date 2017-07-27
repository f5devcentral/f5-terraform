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
variable management_gui_port  { default = "443" }


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
variable proxy_aws_image_name       { default = "Best"       }  # ex. "Good, Better or Best"


# LICENSE
variable aws_proxy_license_key_1     {}
variable aws_proxy_license_key_2     {}

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
    source         = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/network?ref=v0.0.8"
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
  source = "github.com/f5devcentral/f5-terraform//modules/providers/aws/application?ref=v0.0.8"
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



####### PROXY

# NOTE: By default, The proxy module assigns EIPs to the mgmt interfaces (which require routes back through the internet gateway (IGW) 
# but but the network module creates network with all subnets except for the public subnet through the NAT Gateway in order to only
# allow outbound traffic.  If you would like to access the BIG-IPs directly (vs. via VPN, Direct Connect), you can just  
# add a route to the "management routing tables" to your client or restricted subnet or point default route 0.0.0.0/0 
# back to the internet gateway (IGW).


resource "aws_security_group" "public_sg" {
  name        = "${var.environment}-proxy-public-int-sg"
  description = "${var.environment}-proxy-public-int-ports"
  vpc_id      = "${module.aws_network.vpc_id}"


  # VIP HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VIP HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Sync or GTM Discovery access from anywhere
  ingress {
    from_port   = 4353
    to_port     = 4353
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HA Heartbeat
  ingress {
    from_port   = 1026
    to_port     = 1026
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  # ping access from internal
  ingress {
    from_port   = 8 
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
      Name           = "${var.environment}-proxy-public-int-sg"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }

}

resource "aws_security_group" "management_sg" {
  name        = "${var.environment}-proxy-management-int-sg"
  description = "${var.environment}-proxy-management-int-ports"
  vpc_id      = "${module.aws_network.vpc_id}"

  # MGMT ssh access 
  ingress {
    from_port   = 22 
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.restricted_src_address}"]
  }

  # MGMT HTTPS access 
  ingress {
    from_port   = "${var.management_gui_port}"
    to_port     = "${var.management_gui_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.restricted_src_address}"]
  }

  # ping access 
  ingress {
    from_port   = 8 
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["${var.restricted_src_address}"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
      Name           = "${var.environment}-proxy-management-int-sg"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }

}

output "proxy_aws_public_sg_id" { value = "${aws_security_group.public_sg.id}" }
output "proxy_aws_management_sg_id" { value = "${aws_security_group.management_sg.id}" }


module "proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/proxy/cluster/across-az-ha/2nic-cft/byol?ref=v0.0.8"
  purpose = "${var.purpose}"
  environment = "${var.environment}"
  application = "${var.application}"
  owner = "${var.owner}"
  group = "${var.group}"
  costcenter = "${var.costcenter}"
  region                  = "${var.aws_region}"
  vpc_id                  = "${module.aws_network.vpc_id}"
  management_subnet_ids   = "${module.aws_network.management_subnet_ids}"
  public_subnet_ids       = "${module.aws_network.public_subnet_ids}"
  public_sg_id            = "${aws_security_group.public_sg.id}"
  management_sg_id        = "${aws_security_group.management_sg.id}"
  ssh_key_name            = "${var.ssh_key_name}"
  restricted_src_address  = "${var.restricted_src_address}"
  instance_type           = "${var.proxy_aws_instance_type}"
  image_name              = "${var.proxy_aws_image_name}"
  license_key_1           = "${var.aws_proxy_license_key_1}"
  license_key_2           = "${var.aws_proxy_license_key_2}"
}

output "bigip_stack_id" { value = "${module.proxy.bigip_stack_id}" }
output "bigip_stack_outputs" { value = "${module.proxy.bigip_stack_outputs}" }

output "Bigip1ExternalInterfacePrivateIp" { value = "${module.proxy.Bigip1ExternalInterfacePrivateIp}" }
output "Bigip1InstanceId" { value = "${module.proxy.Bigip1InstanceId}" }
output "Bigip1ManagementEipAddress" { value = "${module.proxy.Bigip1ManagementEipAddress}" }
output "Bigip1ManagementInterface" { value = "${module.proxy.Bigip1ManagementEipAddress}" }
output "Bigip1ManagementInterfacePrivateIp" { value = "${module.proxy.Bigip1ManagementInterfacePrivateIp}" }
output "Bigip1Url" { value = "${module.proxy.Bigip1Url}" }
output "Bigip1VipEipAddress" { value = "${module.proxy.Bigip1VipEipAddress}" }
output "Bigip1VipPrivateIp" { value = "${module.proxy.Bigip1VipPrivateIp}" }
output "Bigip1subnet1Az1Interface" { value = "${module.proxy.Bigip1subnet1Az1Interface}" }
output "Bigip1subnet1Az1SelfEipAddress" { value = "${module.proxy.Bigip1subnet1Az1SelfEipAddress}" }
output "availabilityZone1" { value = "${module.proxy.availabilityZone1}" }

output "Bigip2ExternalInterfacePrivateIp" { value = "${module.proxy.Bigip2ExternalInterfacePrivateIp}" }
output "Bigip2InstanceId" { value = "${module.proxy.Bigip2InstanceId}" }
output "Bigip2ManagementEipAddress" { value = "${module.proxy.Bigip2ManagementEipAddress}" }
output "Bigip2ManagementInterface" { value = "${module.proxy.Bigip2ManagementEipAddress}" }
output "Bigip2ManagementInterfacePrivateIp" { value = "${module.proxy.Bigip2ManagementInterfacePrivateIp}" }
output "Bigip2Url" { value = "${module.proxy.Bigip2Url}" }
output "Bigip2VipEipAddress" { value = "${module.proxy.Bigip2VipEipAddress}" }
output "Bigip2VipPrivateIp" { value = "${module.proxy.Bigip2VipPrivateIp}" }
output "Bigip2subnet1Az2Interface" { value = "${module.proxy.Bigip2subnet1Az2Interface}" }
output "Bigip2subnet1Az2SelfEipAddress" { value = "${module.proxy.Bigip2subnet1Az2SelfEipAddress}" }
output "availabilityZone2" { value = "${module.proxy.availabilityZone2}" }
