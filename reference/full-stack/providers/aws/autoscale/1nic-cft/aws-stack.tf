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
variable vs_port               { default = "80"}
variable pool_member_address   { default = "10.0.3.4" }
variable pool_member_port      { default = "80" }
variable pool_name             { default = "default" }  # Either DNS or Autoscale Group Name, No spaces allowed
variable pool_tag_key          { default = "Name" }
variable pool_tag_value        { default = "dev-www-instance" }

# AUTO SCALE
variable proxy_scale_min                    { default = 1 }
variable proxy_scale_max                    { default = 3 }
variable proxy_scale_desired                { default = 2 }
variable proxy_scale_down_bytes_threshold   { default = "10000" }
variable proxy_scale_up_bytes_threshold     { default = "35000" }
variable proxy_notification_email           { default = "user@example.com" }



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
variable proxy_throughput           { default = "25Mbps" }



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

### NETWORK

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



### APP

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



### PROXY

resource "aws_security_group" "proxy_lb_sg" {
  name        = "${var.environment}-proxy-lb-sg"
  vpc_id      = "${module.aws_network.vpc_id}"
  description = "Security group for app ELB"

  lifecycle { create_before_destroy = true }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {      
      Name           = "proxy-lb-sg"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }
}


resource "aws_iam_server_certificate" "proxy_cert" {
  name             = "${var.environment}-proxy-crt"
  certificate_body = "${file(var.site_ssl_cert)}"
  private_key      = "${file(var.site_ssl_key)}"

  lifecycle { create_before_destroy = true }

  provisioner "local-exec" {
    command = <<EOF
      echo "Sleep 10 secends so that the cert is propagated by aws iam service"
      echo "See https://github.com/hashicorp/terraform/issues/2499 (terraform ~v0.6.1)"
      sleep 10
EOF
  }
}

resource "aws_elb" "proxy_lb" {
  name                        = "${var.environment}-proxy-lb"
  security_groups = ["${aws_security_group.proxy_lb_sg.id}"]
  subnets         = ["${split(",", module.aws_network.public_subnet_ids)}"]
  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 60

  lifecycle { create_before_destroy = true }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  listener {
    lb_port            = 443
    lb_protocol        = "https"
    instance_port      = 80
    instance_protocol  = "http"
    ssl_certificate_id = "${aws_iam_server_certificate.proxy_cert.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 15
    target              = "HTTP:80/"
  }

  tags {      
      Name           = "${var.environment}-proxy-lb"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }
}



module "proxy" {
  source                  = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/proxy/autoscale/1nic-cft/util?ref=v0.0.9"
  deployment_name         = "${var.deployment_name}"
  purpose                 = "${var.purpose}"
  environment             = "${var.environment}"
  application             = "${var.application}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  region                  = "${var.aws_region}"
  availability_zones      = "${var.aws_availability_zones}"
  vpc_id                  = "${module.aws_network.vpc_id}"
  subnet_ids              = "${module.aws_network.public_subnet_ids}"
  ssh_key_name            = "${var.ssh_key_name}"
  throughput              = "${var.proxy_throughput}"
  instance_type           = "${var.proxy_aws_instance_type}"
  admin_username          = "${var.admin_username}"
  ntp_server              = "${var.ntp_server}"
  timezone                = "${var.timezone}"
  vs_port                 = "${var.vs_port}"
  pool_member_port        = "${var.pool_member_port}"
  pool_name               = "${var.pool_name}"
  pool_tag_key            = "${var.pool_tag_key}"
  pool_tag_value          = "${var.pool_tag_value}"
  notification_email      = "${var.proxy_notification_email}"
  bigip_elb               = "${aws_elb.proxy_lb.name}"
}

#### OUTPUTS 

output "proxy_cert_id" { value = "${aws_iam_server_certificate.proxy_cert.id}" }
output "proxy_cert_name" { value = "${aws_iam_server_certificate.proxy_cert.name}" }
output "proxy_cert_arn" { value = "${aws_iam_server_certificate.proxy_cert.arn}" }

output "proxy_lb_id" { value = "${aws_elb.proxy_lb.id}" }
output "proxy_lb_name" { value = "${aws_elb.proxy_lb.name}" }
output "proxy_lb_dns_name" { value = "${aws_elb.proxy_lb.dns_name}" }

output "bigip_stack_id" { value = "${module.proxy.bigip_stack_id}" }
output "bigip_stack_outputs" { value = "${module.proxy.bigip_stack_outputs}" }
output "bigipAutoscaleGroup" { value = "${module.proxy.bigipAutoscaleGroup}" }
output "s3Bucket" { value = "${module.proxy.s3Bucket}" }





