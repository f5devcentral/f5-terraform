# TAGS
variable purpose        { default = "public"       }  
variable environment    { default = "dev"          }  
variable application    { default = "f5app"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      } 
variable costcenter     { default = "f5costcenter" } 


# NETWORK:
variable region                   { default = "us-west-2"  }
variable vpc_id                   {}
variable management_subnet_ids    {}
variable public_subnet_ids        {}

# SYSTEM
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
variable management_gui_port  { default = "443" }

# PROXY:
variable instance_type  { default = "m4.2xlarge" }
variable image_name     { default = "Best"       }  # ex. "Good, Better or Best"


# SECURITY
variable public_ssh_key_path    {}  # ex. "~/.ssh/my-terraform-key.pem.pub"
variable ssh_key_name           {}  # example "my-terraform-key"
variable restricted_src_address { default = "0.0.0.0/0" }

# LICENSE
variable license_key_1 {}  # ex. "XXXXX-XXXXX-XXXXX-XXXXX-XXXXXXX"
variable license_key_2 {}


#### RESROUCES

provider "aws" {
  region = "${var.region}"
}

#A key pair is used to control login access to EC2 instances
resource "aws_key_pair" "auth" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${file(var.public_ssh_key_path)}"
}

resource "aws_security_group" "public_sg" {
  name        = "${var.environment}-proxy-public-int-sg"
  description = "${var.environment}-proxy-public-int-ports"
  vpc_id      = "${var.vpc_id}"


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
  vpc_id      = "${var.vpc_id}"

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


module "proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/proxy/cluster/across-az-ha/2nic-cft/byol"
  purpose = "${var.purpose}"
  environment = "${var.environment}"
  application = "${var.application}"
  owner = "${var.owner}"
  group = "${var.group}"
  costcenter = "${var.costcenter}"
  region = "${var.region}"
  vpc_id = "${var.vpc_id}"
  management_subnet_ids = "${var.management_subnet_ids}"
  public_subnet_ids = "${var.public_subnet_ids}"
  public_sg_id  = "${aws_security_group.public_sg.id}"
  management_sg_id = "${aws_security_group.management_sg.id}"
  ssh_key_name = "${var.ssh_key_name}"
  restricted_src_address = "${var.restricted_src_address}"
  instance_type = "${var.instance_type}"
  image_name = "${var.image_name}"
  license_key_1 = "${var.license_key_1}"
  license_key_2 = "${var.license_key_2}"
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
