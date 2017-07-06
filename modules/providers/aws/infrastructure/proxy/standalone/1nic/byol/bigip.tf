### VARIABLES ###

# TAGS
variable purpose        { default = "public"       }  
variable environment    { default = "dev"          }  
variable application    { default = "f5app"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      } 
variable costcenter     { default = "f5costcenter" } 

# PLACEMENT
variable region                 { default = "us-west-2"  }
variable vpc_id                 {}
variable availability_zone      { default = "us-west-2a" }
variable subnet_id              {}

# PROXY
variable instance_type  { default = "m4.2xlarge" }
variable image_id       {}


# SYSTEM
variable dns_server           { default = "8.8.8.8" }
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
variable management_gui_port  { default = "8443" }

# NETWORK
variable create_management_public_ip  { default = true }

# SECURITY
variable admin_username {}
variable admin_password {}

variable ssh_key_name        {}  # example "my-terraform-key"
variable restricted_src_address { default = "0.0.0.0/0" }


# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }

# APPLICATION
variable vs_dns_name      { default = "www.example.com" }
variable vs_address       { default = "0.0.0.0" }
variable vs_mask          { default = "0.0.0.0" }
variable vs_port          { default = "443" }

# SERVICE DISCOVERY
variable pool_member_port { default = "80" }
variable pool_name        { default = "www.example.com" }  # DNS (ex. "www.example.com") used to create fqdn node if there's no Service Discovery iApp 
variable pool_tag_key     { default = "Name" }
variable pool_tag_value   { default = "dev-demo-instance" }

# LICENSE
variable license_key {}   # ex. "XXXXX-XXXXX-XXXXXX-XXXXXX"


### RESOURCES ###

provider "aws" {
  region = "${var.region}"
}

resource "aws_security_group" "sg" {
  name        = "${var.environment}_proxy_sg"
  description = "${var.environment}_proxy_ports"
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

  # VIP HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VIP HTTPS access from anywhere
  ingress {
    from_port   = "${var.vs_port}"
    to_port     = "${var.vs_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
      Name           = "${var.environment}_proxy_sg"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }

}

resource "aws_iam_role_policy" "proxy_service_discovery_policy" {
  name = "proxy_service_discovery_policy"
  role = "${aws_iam_role.proxy_service_discovery_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeAddresses",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeNetworkInterfaceAttributes",
        "ec2:DescribeRouteTables",
        "ec2:ReplaceRoute",
        "autoscaling:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "proxy_service_discovery_role" {
  name = "proxy_service_discovery_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_instance_profile" "proxy_service_discovery_profile" {
  name  = "proxy_service_discovery_profile"
  role = "${aws_iam_role.proxy_service_discovery_role.name}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    admin_username        = "${var.admin_username}"
    admin_password        = "${var.admin_password}"
    management_gui_port   = "${var.management_gui_port}"
    dns_server            = "${var.dns_server}"
    ntp_server            = "${var.ntp_server}"
    timezone              = "${var.timezone}"
    region                = "${var.region}"
    application           = "${var.application}"
    vs_dns_name           = "${var.vs_dns_name}"
    vs_address            = "${var.vs_address}"
    vs_mask               = "${var.vs_mask}"
    vs_port               = "${var.vs_port}"
    pool_member_port      = "${var.pool_member_port}"
    pool_name             = "${var.pool_name}"
    pool_tag_key          = "${var.pool_tag_key}"
    pool_tag_value        = "${var.pool_tag_value}"
    site_ssl_cert         = "${var.site_ssl_cert}"
    site_ssl_key          = "${var.site_ssl_key}"
    license_key           = "${var.license_key}"
  }
}

resource "aws_instance" "bigip" {
    ami = "${var.image_id}"
    instance_type = "${var.instance_type}"
    associate_public_ip_address = "${var.create_management_public_ip}"
    availability_zone = "${var.availability_zone}"
    subnet_id = "${var.subnet_id}"
    vpc_security_group_ids = ["${aws_security_group.sg.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.proxy_service_discovery_profile.name}"
    key_name = "${var.ssh_key_name}"
    root_block_device { delete_on_termination = true }
    tags {
      Name           = "${var.environment}_proxy"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
    }
    user_data = "${data.template_file.user_data.rendered}"
}


### OUTPUTS ###

output "sg_id" { value = "${aws_security_group.sg.id}" }
output "sg_name" { value = "${aws_security_group.sg.name}" }

output "instance_id" { value = "${aws_instance.bigip.id}"  }
output "instance_private_ip" { value = "${aws_instance.bigip.private_ip}" }
output "instance_public_ip" { value = "${aws_instance.bigip.public_ip}" }



