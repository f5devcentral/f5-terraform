# CREATES 1NIC BIG-IP + SECURITY GROUP

### VARIABLES ###

variable template_url { default = "https://s3.amazonaws.com/f5-cft/f5-autoscale-bigip.template" }

variable deployment_name { default = "example" }

# TAGS
variable purpose        { default = "public"       }  
variable environment    { default = "dev"          }  
variable application    { default = "f5app"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      } 
variable costcenter     { default = "f5costcenter" } 

# NETWORK:
variable region                 { default = "us-west-2"  }
variable availability_zones     { default = "us-west-2a,us-west-2b" }
variable vpc_id                 {}
variable subnet_ids             {}


# SYSTEM
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
variable management_gui_port  { default = "8443" }

# PROXY:
variable instance_type  { default = "m4.2xlarge" }
variable throughput     { default = "25Mbps" }

# SECURITY
variable public_ssh_key_path  {}
variable ssh_key_name   {}
variable restricted_src_address { default = "0.0.0.0/0" }

variable admin_username {}
# variable admin_password {}

# APPLICATION
variable site_ssl_cert    {}
variable site_ssl_key     {}

variable vs_dns_name           { default = "www.example.com" }
variable vs_port               { default = "80"}
variable pool_member_port      { default = "80" }
variable pool_name             { default = "default" }  # Either DNS or Autoscale Group Name, No spaces allowed
variable pool_tag_key          { default = "Name" }
variable pool_tag_value        { default = "dev-www-instance" }

# AUTO SCALE 
variable scale_min                    { default = 2 }
variable scale_max                    { default = 8 }
variable scale_desired                { default = 2 }
variable scale_down_bytes_threshold   { default = "10000" }
variable scale_up_bytes_threshold     { default = "35000" }

variable notification_email           {}


####### RESROUCES

provider "aws" {
  region = "${var.region}"
}

#A key pair is used to control login access to EC2 instances
resource "aws_key_pair" "auth" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${file(var.public_ssh_key_path)}"
}

resource "aws_security_group" "proxy_lb_sg" {
  name        = "${var.environment}-proxy-lb-sg"
  vpc_id      = "${var.vpc_id}"
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
  subnets         = ["${split(",", var.subnet_ids)}"]
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
  region                  = "${var.region}"
  availability_zones      = "${var.availability_zones}"
  vpc_id                  = "${var.vpc_id}"
  subnet_ids              = "${var.subnet_ids}"
  ssh_key_name            = "${var.ssh_key_name}"
  throughput              = "${var.throughput}"
  instance_type           = "${var.instance_type}"
  admin_username          = "${var.admin_username}"
  ntp_server              = "${var.ntp_server}"
  timezone                = "${var.timezone}"
  vs_port                 = "${var.vs_port}"
  pool_member_port        = "${var.pool_member_port}"
  pool_name               = "${var.pool_name}"
  pool_tag_key            = "${var.pool_tag_key}"
  pool_tag_value          = "${var.pool_tag_value}"
  notification_email      = "${var.notification_email}"
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




