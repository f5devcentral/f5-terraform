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


# NOTE: Get creds from environment variables
provider "google" {
    region = "${var.region}"
}

resource "google_compute_network" "network" {
  name                    = "${var.environment}-network"
  auto_create_subnetworks = "false"

  provisioner "local-exec" {
    command = <<EOF
      echo "Address Eventual Consistent APIs: -subnet is not ready, resourceNotReady"
      echo "See https://github.com/hashicorp/terraform/issues/2499"
      echo "https://github.com/hashicorp/terraform/issues/14970"
      sleep 15
EOF

  }


}

resource "google_compute_subnetwork" "subnet_public" {
  name          = "${var.environment}-public-subnet"
  ip_cidr_range = "${var.subnet_public_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"

  provisioner "local-exec" {
    command = <<EOF
      echo "Address Eventual Consistent APIs: -subnet is not ready, resourceNotReady"
      echo "See https://github.com/hashicorp/terraform/issues/2499"
      echo "https://github.com/hashicorp/terraform/issues/14970"
      sleep 15
EOF

  }

}


resource "google_compute_subnetwork" "subnet_management" {
  name          = "${var.environment}-management-subnet"
  ip_cidr_range = "${var.subnet_management_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"
}


resource "google_compute_subnetwork" "subnet_private" {
  name          = "${var.environment}-private-subnet"
  ip_cidr_range = "${var.subnet_private_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"
}

resource "google_compute_subnetwork" "subnet_application" {
  name          = "${var.environment}-application-subnet"
  ip_cidr_range = "${var.subnet_application_cidr_block}"
  network       = "${google_compute_network.network.name}"
  region        = "${var.region}"
}


output "network"            { value = "${google_compute_network.network.name}"  }
output "subnet_management"  { value = "${google_compute_subnetwork.subnet_management.name}"  }
output "subnet_public"      { value = "${google_compute_subnetwork.subnet_public.name}"  }
output "subnet_private"     { value = "${google_compute_subnetwork.subnet_private.name}"  }
output "subnet_application" { value = "${google_compute_subnetwork.subnet_application.name}"  }