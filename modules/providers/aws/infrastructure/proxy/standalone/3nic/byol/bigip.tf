# CREATES 3NIC BIG-IP

### VARIABLES ###

# TAGS
variable purpose        { default = "public"       }  
variable environment    { default = "dev"          }  
variable application    { default = "f5app"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      } 
variable costcenter     { default = "f5costcenter" } 


# NETWORK:
variable region                 { default = "us-west-2"  }
variable availability_zone      { default = "us-west-2a" }
variable vpc_id                 {}
variable management_subnet_id   {}
variable management_address     { default = "10.0.0.11"   }
variable subnet_1_id            {}
variable subnet_1_name          { default = "public"      }
variable subnet_1_address       { default = "10.0.1.11"   }
variable subnet_1_cidr_block    { default = "10.0.1.0/24" }
variable subnet_1_mtu           { default = "1500"        }
variable subnet_2_id            {}
variable subnet_2_name          { default = "private"      }
variable subnet_2_address       { default = "10.0.2.11"   }
variable subnet_2_cidr_block    { default = "10.0.2.0/24" }
variable subnet_2_mtu           { default = "1500"        }

variable default_gateway        { default = "10.0.1.1"    }


# Public IPs. a Public NAT
# NOTE: either NAT gateway or other NAT service is required for BIG-IP to operate
# It needs internet access through the MGMT interface & Interface with Default Gateway
# which is ususally subnet_1 (aka "Public" or "External" interface)
variable create_management_public_ip  { default = false         }
variable create_subnet_1_public_ip    { default = true          }
variable create_vs_public_ip          { default = true          }


# SYSTEM
variable dns_server           { default = "8.8.8.8" }
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
variable management_gui_port  { default = "443" }

# PROXY:
variable instance_type  { default = "m4.2xlarge" }
variable amis { 
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
variable vs_address       { default = "10.0.1.100" }  #do not use 0.0.0.0 as used to to provision secondary IP address on public nic
variable vs_mask          { default = "255.255.255.255" }
variable vs_port          { default = "443" }

# SERVICE DISCOVERY
variable pool_member_port { default = "80" }
variable pool_name        { default = "www.example.com" }  # DNS (ex. "www.example.com") used to create fqdn node if there's no Service Discovery iApp 
variable pool_tag_key     { default = "Name" }
variable pool_tag_value   { default = "dev-www-instance" }


# LICENSE
variable license_key {}   # ex. "XXXXX-XXXXX-XXXXXX-XXXXXX"


### RESOURCES ###

resource "aws_security_group" "public_int_sg" {
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

resource "aws_security_group" "management_int_sg" {
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
    from_port   = 8443
    to_port     = 8443
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

resource "aws_security_group" "private_int_sg" {
  name        = "${var.environment}-proxy-private-int-sg"
  description = "${var.environment}-proxy-private-int-ports"
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
    from_port   = 443
    to_port     = 443
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
      Name           = "${var.environment}-proxy-private-int-sg"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }

}


resource "aws_network_interface" "public_int" {
    subnet_id = "${var.subnet_1_id}"
    private_ips = ["${var.subnet_1_address}","${var.vs_address}"]
    security_groups = ["${aws_security_group.public_int_sg.id}"]
    attachment {
        instance = "${aws_instance.bigip.id}"
        device_index = 1
    }
}

resource "aws_network_interface" "private_int" {
    depends_on = ["aws_network_interface.public_int"]
    subnet_id = "${var.subnet_2_id}"
    private_ips = ["${var.subnet_2_address}"]
    security_groups = ["${aws_security_group.private_int_sg.id}"]
    attachment {
        instance = "${aws_instance.bigip.id}"
        device_index = 2
    }
}


resource "aws_eip" "public_self_eip" {
  count                     = "${var.create_subnet_1_public_ip}"
  vpc                       = true
  network_interface         = "${aws_network_interface.public_int.id}"
  associate_with_private_ip = "${var.subnet_1_address}"
}

resource "aws_eip" "virtual_service_eip" {
  count                     = "${var.create_vs_public_ip}"
  vpc                       = true
  network_interface         = "${aws_network_interface.public_int.id}"
  associate_with_private_ip = "${var.vs_address}"
}


resource "aws_iam_role_policy" "proxy_service_discovery_policy" {
  name = "proxy-service-discovery-policy"
  role = "${aws_iam_role.proxy_service_discovery_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
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
  name = "proxy-service-discovery-role"

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
  name  = "proxy-service-discovery-profile"
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
    subnet_1_name         = "${var.subnet_1_name}"
    subnet_1_address      = "${var.subnet_1_address}" 
    subnet_1_cidr_block   = "${var.subnet_1_cidr_block}"
    subnet_1_mtu          = "${var.subnet_1_mtu}"
    subnet_2_name         = "${var.subnet_2_name}"
    subnet_2_address      = "${var.subnet_2_address}" 
    subnet_2_cidr_block   = "${var.subnet_2_cidr_block}"
    subnet_2_mtu          = "${var.subnet_2_mtu}" 
    default_gateway       = "${var.default_gateway}" 
    application           = "${var.application}"
    region                = "${var.region}"
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
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.instance_type}"
    associate_public_ip_address = "${var.create_management_public_ip}"
    private_ip = "${var.management_address}" 
    availability_zone = "${var.availability_zone}"
    subnet_id = "${var.management_subnet_id}"
    vpc_security_group_ids = ["${aws_security_group.management_int_sg.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.proxy_service_discovery_profile.name}"
    key_name = "${var.ssh_key_name}"
    root_block_device { delete_on_termination = true }
    tags {
      Name           = "${var.environment}-proxy"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
    }
    user_data = "${data.template_file.user_data.rendered}"
}



### OUTPUTS ###

output "instance_id" { value = "${aws_instance.bigip.id}"  }

output "management_int_sg_id" { value = "${aws_security_group.management_int_sg.id}" }
output "management_int_sg_name" { value = "${aws_security_group.management_int_sg.name}" }

output "public_int_sg_id" { value = "${aws_security_group.public_int_sg.id}" }
output "public_int_sg_name" { value = "${aws_security_group.public_int_sg.name}" }

output "private_int_sg_id" { value = "${aws_security_group.private_int_sg.id}" }
output "private_int_sg_name" { value = "${aws_security_group.private_int_sg.name}" }

output "management_int_private_ip" { value = "${aws_instance.bigip.private_ip}" }
output "management_int_public_ip" { value = "${aws_instance.bigip.public_ip}" }

output "public_int_public_ip" { value = "${aws_eip.public_self_eip.public_ip}" }
output "public_int_private_ip" { value = "${aws_network_interface.public_int.private_ips[0]}" }

output "private_int_private_ip" { value = "${aws_network_interface.private_int.private_ips[0]}" }

output "virtual_service_public_ip" { value = "${aws_eip.virtual_service_eip.public_ip}" }


