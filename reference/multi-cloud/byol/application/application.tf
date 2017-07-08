# GLOBAL
variable deployment_name  { default = "demo" }

# TAGS
variable application_dns  { default = "www.example.com" }  # ex. "www.example.com"
variable application      { default = "www"             }  # ex. "www" - short name used in object naming
variable environment      { default = "f5env"           }  # ex. dev/staging/prod
variable owner            { default = "f5owner"         }  
variable group            { default = "f5group"         }
variable costcenter       { default = "f5costcenter"    }  
variable purpose          { default = "public"          } 


#####  APPLICATION: 
variable docker_image       { default = "f5devcentral/f5-demo-app:lates"  }
variable aws_docker_image   { default = "f5devcentral/f5-demo-app:AWS"    }
variable azure_docker_image { default = "f5devcentral/f5-demo-app:azure"  }
variable gce_docker_image   { default = "f5devcentral/f5-demo-app:google" }

# SECURITY / KEYS
variable admin_username { default = "custom-admin" }
variable admin_password {}


variable ssh_key_public         {}  # string of key ex. "ssh-rsa AAAA..."
variable ssh_key_name           {}
variable restricted_src_address { default = "0.0.0.0/0" }

# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }

# AUTO SCALE
variable throughput                   { default = "25Mbps" }
variable scale_min                    { default = 1 }
variable scale_max                    { default = 3 }
variable scale_desired                { default = 2 }
variable scale_down_bytes_threshold   { default = "10000" }
variable scale_up_bytes_threshold     { default = "35000" }
variable notification_email           { default = "user@example.com" }


######## PROVIDER #######

##### AWS PLACEMENT
variable aws_region             { default = "us-west-2" }

# NETWORK:
variable aws_vpc_id             {}
variable aws_availability_zones { default = "us-west-2a,us-west-2b" }
variable aws_subnet_ids         {}

##### AWS COMPUTE:
variable aws_instance_type      { default = "t2.small" }
variable aws_amis {     
    type = "map" 
    default = {
        "ap-northeast-1" = "ami-c9e3c0ae"
        "ap-northeast-2" = "ami-3cda0852"
        "ap-southeast-1" = "ami-6e74ca0d"
        "ap-southeast-2" = "ami-92e8e6f1"
        "eu-central-1" = "ami-1b4d9e74"
        "eu-west-1" = "ami-b5a893d3"
        "sa-east-1" = "ami-36187a5a"
        "us-east-1" = "ami-e4139df2"
        "us-east-2" = "ami-33ab8f56"
        "us-west-1" = "ami-30476250"
        "us-west-2" = "ami-17ba2a77"
    }
}

### AZURE PLACEMENT
variable azure_region           { default = "West US" } 
variable azure_resource_group   { default = "app.example.com" }

# NETWORK:
variable azure_vnet_id              {}
variable azure_vnet_resource_group  { default = "network.example.com" }
# Required for Standalone
variable azure_subnet_id            {}

##### AZURE COMPUTE:
variable azure_instance_type        { default = "Standard_A0" }
variable instance_name_prefix       { default = "appvm" }


##### GCE PLACEMENT
variable gce_region         { default = "us-west1"   } 
variable gce_zone           { default = "us-west1-a" } 

# NETWORK:
variable gce_network        { default = "demo-network" }
variable gce_subnet_id      { default = "demo-application-subnet" }

# Application
variable gce_instance_type  { default = "n1-standard-1" }


########################################

provider "aws" {
  region = "${var.aws_region}"
}


module "aws_app" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/aws/application?ref=v0.0.7"
  docker_image            = "${var.aws_docker_image}"
  application_dns         = "${var.application_dns}"
  application             = "${var.application}"
  environment             = "${var.environment}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  purpose                 = "${var.purpose}"
  region                  = "${var.aws_region}"
  vpc_id                  = "${var.aws_vpc_id}"
  availability_zones      = "${var.aws_availability_zones}"
  subnet_ids              = "${var.aws_subnet_ids}"
  amis                    = "${var.aws_amis}"
  instance_type           = "${var.aws_instance_type}"
  ssh_key_name            = "${var.ssh_key_name}"
  restricted_src_address  = "${var.restricted_src_address}"
}

output "aws_sg_id" { value = "${module.aws_app.sg_id}" }
output "aws_sg_name" { value = "${module.aws_app.sg_name}" }

output "aws_asg_id" { value = "${module.aws_app.asg_id}" }
output "aws_asg_name" { value = "${module.aws_app.asg_name}" }



########################################

provider "azurerm" {
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.azure_resource_group}"
  location = "${var.azure_region}"

  tags {
    environment = "${var.environment}-${var.azure_resource_group}"
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "Address Eventual Consistent APIs: Re: Status=404 Code=ResourceGroupNotFound"
      echo "See https://github.com/hashicorp/terraform/issues/2499"
      echo "https://github.com/hashicorp/terraform/issues/14970"
      sleep 10
EOF

  }

}


module "azure_app" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/azure/application?ref=v0.0.7"
  docker_image            = "${var.azure_docker_image}"
  application_dns         = "${var.application_dns}"
  application             = "${var.application}"
  environment             = "${var.environment}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  purpose                 = "${var.purpose}"
  region                  = "${var.azure_region}"
  resource_group          = "${azurerm_resource_group.resource_group.name}"
  vnet_id                 = "${var.azure_vnet_id}"
  subnet_id               = "${var.azure_subnet_id}"
  instance_type           = "${var.azure_instance_type}"
  instance_name_prefix    = "${var.instance_name_prefix}"
  ssh_key_public          = "${var.ssh_key_public}"
  restricted_src_address  = "${var.restricted_src_address}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
}

output "azure_sg_id" { value = "${module.azure_app.sg_id}" }
output "azure_sg_name" { value = "${module.azure_app.sg_name}" }

output "azure_lb_id" { value = "${module.azure_app.lb_id}" }
output "azure_lb_private_ip" { value = "${module.azure_app.lb_private_ip}" }
output "azure_lb_public_ip" { value = "${module.azure_app.lb_public_ip}" }


########################################

provider "google" {
  region = "${var.gce_region}"
}

module "gce_app" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/gce/application?ref=v0.0.7"
  docker_image            = "${var.gce_docker_image}"
  application_dns         = "${var.application_dns}"
  application             = "${var.application}"
  environment             = "${var.environment}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  purpose                 = "${var.purpose}"
  region                  = "${var.gce_region}"
  zone                    = "${var.gce_zone}"
  network                 = "${var.gce_network}"
  subnet_id               = "${var.gce_subnet_id}"
  instance_type           = "${var.gce_instance_type}"
  ssh_key_public          = "${var.ssh_key_public}"
  restricted_src_address  = "${var.restricted_src_address}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
}

output "gce_sg_id" { value = "${module.gce_app.sg_id}" }
output "gce_lb_public_ip" { value = "${module.gce_app.lb_public_ip}" }


