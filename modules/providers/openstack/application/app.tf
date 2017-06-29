### VARIABLES ###

# TAGS
variable application_dns  { default = "www.example.com" }  # ex. "www.example.com"
variable application      { default = "www"             }  # ex. "www" - short name used in object naming
variable environment      { default = "f5env"           }  # ex. dev/staging/prod
variable owner            { default = "f5owner"         }  
variable group            { default = "f5group"         }
variable costcenter       { default = "f5costcenter"    }  
variable purpose          { default = "public"          }  

# PLACEMENT
variable network_id              {}

variable restricted_src_address  { default = "0.0.0.0/0" }


# Application
variable docker_image   { default = "f5devcentral/f5-demo-app:latest" }

variable image_id       {}
# variable instance_type  {}
# variable instance_size  {}
variable flavor_id {}


variable admin_username {}
variable admin_password {}
variable ssh_key_public {} # string ex. ssh-rsa AAAAB3XXXXXXZZZZZZZZZZZZ"

# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }

# Autoscale
variable scale_min      { default = 1 }
variable scale_max      { default = 3 }
variable scale_desired  { default = 1 }



# NOTE: Get creds from environment variables
provider "openstack" {
}

resource "openstack_compute_secgroup_v2" "secgroup" {
  name        = "${var.environment}_app_sg"
  description = "my security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "${var.restricted_src_address}"
  } 

  rule {
    from_port   = "80"
    to_port     = "80"
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # VIRTUAL SERVER
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    docker_image          = "${var.docker_image}"
  }

}


resource "openstack_networking_floatingip_v2" "myip" {
  pool = "public"
}

resource "openstack_compute_instance_v2" "app" {
  name            = "${var.environment}-${var.application}-app"
  image_id        = "${var.image_id}"
  flavor_id       = "${var.flavor_id}"
  key_pair        = "${var.ssh_key_name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup.name}"]
  config_drive = "True"

  network {
    uuid = "${var.network_id}"
    #  name = doesn't seem to work
    #  Error creating OpenStack server: Invalid request due to incorrect syntax or missing required parameters.
    #  TF_LOG=DEBUG OS_DEBUG=1 terraform apply 
    #  yields "message": "Bad network format: missing 'uuid'"
  }
  
  user_data = "${data.template_file.user_data.rendered}"

}

resource "openstack_compute_floatingip_associate_v2" "myip" {
  floating_ip = "${openstack_networking_floatingip_v2.myip.address}"
  instance_id = "${openstack_compute_instance_v2.app.id}"
  fixed_ip = "${openstack_compute_instance_v2.app.network.0.fixed_ip_v4}"
}

