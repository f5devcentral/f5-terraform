# TAGS
variable application_dns  { default = "www.example.com" }  # ex. "www.example.com"
variable application      { default = "www"             }  # ex. "www" - short name used in object naming
variable environment      { default = "f5env"           }  # ex. dev/staging/prod
variable owner            { default = "f5owner"         }  
variable group            { default = "f5group"         }
variable costcenter       { default = "f5costcenter"    }  
variable purpose          { default = "public"          }  

# PLACEMENT
variable region                 { default = "us-west-2" }
variable vpc_id                 {}
variable availability_zones     { default = "us-west-2a,us-west-2b"}
variable subnet_ids             {}


# APPLICATION
variable docker_image   { default = "f5devcentral/f5-demo-app:AWS" }
variable image_id       {}
variable instance_type  { default = "t2.small" }

variable ssh_key_name   {}
# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }

# AUTO SCALE
variable scale_min      { default = 1 }
variable scale_max      { default = 3 }
variable scale_desired  { default = 1 }


### RESOURCES ###

resource "aws_security_group" "sg" {
  name        = "${var.application}_app_sg"
  description = "${var.application}_app_ports"
  vpc_id      = "${var.vpc_id}"

  # ssh access from anywhere
  ingress {
    from_port   = 22 
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ping access from anywhere
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
      Name           = "${var.environment}-${var.application}-app-sg"
      application    = "${var.application}"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"

  }
}


data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    docker_image        = "${var.docker_image}"
  }
}

resource "aws_launch_configuration" "as_conf" {
  name_prefix         = "${var.application}_app_lc_"
  key_name            = "${var.ssh_key_name}"
  image_id            = "${var.image_id}"
  instance_type       = "${var.instance_type}"
  security_groups     = ["${aws_security_group.sg.id}"]
  user_data           = "${data.template_file.user_data.rendered}"
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
  }
}

# NOTE App Pool Name Hardcoded
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.application}_app_asg"
  vpc_zone_identifier       = ["${split(",", var.subnet_ids)}"] 
  availability_zones        = ["${split(",", var.availability_zones)}"]
  min_size                  = "${var.scale_min}"
  max_size                  = "${var.scale_max}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.as_conf.name}"
  tag {
    key = "Name"
    value = "${var.environment}-${var.application}-instance"
    propagate_at_launch = true
  }

  tag {
    key = "application"
    value = "${var.application}"
    propagate_at_launch = true
  }

  tag {
    key = "environment"
    value = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key = "owner"
    value = "${var.owner}"
    propagate_at_launch = true
  }

  tag {
    key = "group"
    value = "${var.group}"
    propagate_at_launch = true
  }

  tag {
    key = "costcenter"
    value = "${var.costcenter}"
    propagate_at_launch = true
  }


}

resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "${var.application}_app_asg_policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}



### OUTPUTS ###


output "sg_id" { value = "${aws_security_group.sg.id}" }
output "sg_name" { value = "${aws_security_group.sg.name}" }

output "asg_id" { value = "${aws_autoscaling_group.asg.id}" }
output "asg_name" { value = "${aws_autoscaling_group.asg.name}" }

