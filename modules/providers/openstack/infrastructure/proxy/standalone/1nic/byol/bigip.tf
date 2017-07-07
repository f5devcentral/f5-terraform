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

# PROXY
variable flavor_id      {}
variable image_id       {}
# variable instance_type  {}
# variable instance_size  {}


# SYSTEM
variable dns_server           { default = "8.8.8.8" }
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
variable management_gui_port  { default = "8443" }

# SECURITY
variable admin_username {}
variable admin_password {}

variable ssh_key_public      {}  # string of key ex. "ssh-rsa AAAA..."
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
variable pool_member_port { default = "80" }
variable pool_name        { default = "www.example.com" }  # DNS (ex. "www.example.com") used to create fqdn node if there's no Service Discovery iApp 

# LICENSE
variable license_key {}


### RESOURCES ###

# NOTE: Get creds from environment variables
provider "openstack" {
}

resource "openstack_compute_secgroup_v2" "secgroup" {
  name        = "${var.environment}-proxy-sg"
  description = "my security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "${var.restricted_src_address}"
  } 

  rule {
    from_port   = "${var.management_gui_port}"
    to_port     = "${var.management_gui_port}"
    ip_protocol = "tcp"
    cidr        = "${var.restricted_src_address}"
  }

  # VIRTUAL SERVER
  rule {
    from_port   = "${var.vs_port}"
    to_port     = "${var.vs_port}"
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

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
    application           = "${var.application}"
    vs_dns_name           = "${var.vs_dns_name}"
    vs_address            = "${var.vs_address}"
    vs_mask               = "${var.vs_mask}"
    vs_port               = "${var.vs_port}"
    pool_name             = "${var.pool_name}"
    pool_member_port      = "${var.pool_member_port}"
    site_ssl_cert         = "${var.site_ssl_cert}"
    site_ssl_key          = "${var.site_ssl_key}"
    license_key           = "${var.license_key}"
  }
}


resource "openstack_networking_floatingip_v2" "myip" {
  pool = "public"
}

resource "openstack_compute_instance_v2" "bigip" {
  name            = "${var.environment}-proxy"
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
  
  # network {
  #   uuid = "my_second_network"
  # }

  user_data = "${data.template_file.user_data.rendered}"


}

resource "openstack_compute_floatingip_associate_v2" "myip" {
  floating_ip = "${openstack_networking_floatingip_v2.myip.address}"
  instance_id = "${openstack_compute_instance_v2.bigip.id}"
  fixed_ip = "${openstack_compute_instance_v2.bigip.network.0.fixed_ip_v4}"
}

