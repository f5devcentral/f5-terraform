# TAGS
variable environment    { default = "f5env"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      }
variable costcenter     { default = "f5costcenter" }  

variable region     { default = "us-west1" } 

variable subnet_management_cidr_block   { default = "10.0.0.0/24" }
variable subnet_public_cidr_block       { default = "10.0.1.0/24" } 
variable subnet_private_cidr_block      { default = "10.0.2.0/24" }
variable subnet_application_cidr_block  { default = "10.0.3.0/24" }


provider "google" {
    region = "${var.region}"
}

resource "google_compute_network" "network" {
  name                    = "${var.environment}-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet_management" {
  name          = "management"
  ip_cidr_range = "${var.subnet_management_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "subnet_public" {
  name          = "public"
  ip_cidr_range = "${var.subnet_public_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "subnet_private" {
  name          = "private"
  ip_cidr_range = "${var.subnet_private_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "subnet_application" {
  name          = "application"
  ip_cidr_range = "${var.subnet_application_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"
}
