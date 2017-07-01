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
variable region         { default = "us-west1"   }
variable zone           { default = "us-west1-a" }

variable network        {}
variable subnet_id      {}

variable restricted_src_address { default = "0.0.0.0/0" }

# Application
variable docker_image   { default = "f5devcentral/f5-demo-app:google" }

variable instance_type  { default = "n1-standard-1" }
variable image_name     { default = "ubuntu-os-cloud/ubuntu-1604-lts" }

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


### RESOURCES ###

provider "google" {
}

resource "google_compute_firewall" "app-firewall" {
  name    = "${var.application}-app-firewall"
  network = "${var.network}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443" ]
  }

  source_ranges = ["${var.restricted_src_address}"]
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    docker_image          = "${var.docker_image}"
  }
}

resource "google_compute_instance_template" "instance_template" {
  # Must be a match of regex '(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)'
  # name           = "${var.application}-instance-template"
  name_prefix  = "${var.application}-instance-template-"
  machine_type   = "${var.instance_type}"
  can_ip_forward = false

  # Must be a match of regex '(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)'
  tags = [ "${var.application}", "${var.environment}", "${var.owner}","${var.group}", "costcenter-${var.costcenter}" ]

  disk {
    source_image = "${var.image_name}"
  }

  network_interface {
    #network = "${var.network}"
    subnetwork = "${var.subnet_id}"

    # Add Public IP to instances
    access_config {
      nat_ip = "" 
    }

  }

  metadata_startup_script = "${data.template_file.user_data.rendered}"

  # Must be a match of regex '(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)'
  metadata {
      Name           = "${var.environment}-${var.application}-instance"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
      ssh-keys       = "${var.admin_username}: ${var.ssh_key_public}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "google_compute_http_health_check" "health_check" {
  name = "${var.application}-health-check"
  timeout_sec        = 1
  check_interval_sec = 5
  request_path = "/"
  port = "80"  

}

resource "google_compute_target_pool" "target_pool" {
  # Must be a match of regex '(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)'
  name = "${var.application}-target-pool"

  health_checks = [
    "${google_compute_http_health_check.health_check.name}"
  ]
}

resource "google_compute_instance_group_manager" "group_manager" {
  name = "${var.application}-group-manager"
  zone = "${var.zone}"

  instance_template  = "${google_compute_instance_template.instance_template.self_link}"
  target_pools       = ["${google_compute_target_pool.target_pool.self_link}"]
  base_instance_name = "${var.application}"
}

resource "google_compute_autoscaler" "autoscaler" {
  # name = 'Must be a match of regex '(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)'
  name   = "${var.application}-autoscaler"
  zone   = "${var.zone}"
  target = "${google_compute_instance_group_manager.group_manager.self_link}"

  autoscaling_policy = {
    min_replicas    = "${var.scale_min}"
    max_replicas    = "${var.scale_max}"
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_address" "public_ip" {
  name = "${var.application}-lb-public-ip"
}

resource "google_compute_forwarding_rule" "lb_rule" {
  name       = "${var.application}-${var.purpose}-lb-rule"
  ip_address = "${google_compute_address.public_ip.address}"
  port_range = "80"
  target     = "${google_compute_target_pool.target_pool.self_link}"
  # network = "${var.network}"
  # subnetwork = "${var.subnet_id}"

}

### OUTPUTS ###


output "sg_id" { value = "${google_compute_firewall.app-firewall.self_link}" }
output "lb_public_ip" { value = "${google_compute_address.public_ip.address}" }



