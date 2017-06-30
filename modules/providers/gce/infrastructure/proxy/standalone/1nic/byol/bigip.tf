# TAGS:
variable application  {}
variable purpose      {}
variable environment  {}
variable owner        {}
variable group        {}
variable costcenter   {}

# NETWORK:
variable region  {}
variable zone    {}

# Required for Standalone
variable network                {}
variable management_subnet_id   {}
variable public_subnet_id       {}
variable private_subnet_id      {}
variable application_subnet_id  {}

# Required for Clusters or Autoscaled Deployments
# variable availability_zones     {}
# variable management_subnet_ids  {}
# variable public_subnet_ids      {}
# variable private_subnet_ids     {}
# variable application_subnet_ids {}

# SECURITY: 
variable public_key_path  {}
variable ssh_key_name     {}
variable restricted_src_address { default = "0.0.0.0/0" }

variable site_ssl_cert    {}
variable site_ssl_key     {}

# SYSTEM
variable dns_server     { default = "8.8.8.8" }
variable ntp_server     { default = "0.us.pool.ntp.org" }
variable timezone       { default = "UTC" }

# LICENSE
variable registration_key {}

# PROXY: 
variable image_id       {}
variable instance_type  {}

variable admin_username   {}
variable admin_password   {}

variable vs_dns_name      {}
variable vs_port          {}
variable pool_name        { default = "www.f5.com" }  # Either DNS or Autoscale Group Name, No spaces allowed
variable pool_member_port {}

# WAF
variable policy_level                 { default = "high"}

# AUTO SCALE 
variable deployment_name              {}
variable throughput                   { default = "25Mbps" }
variable scaling_min_size             { default = "1" }
variable scaling_max_size             { default = "8" }
variable scale_down_bytes_threshold   { default = "10000" }
variable scale_up_bytes_threshold     { default = "35000" }
variable notification_email           {}


########################################


provider "google" {
    region = "${var.region}"
}


# 1 NIC STANDALONE
module "my_proxy" {
  source = "./standalone/1nic/byol"
  purpose = "${var.purpose}"
  environment = "${var.environment}"
  application = "${var.application}"
  owner = "${var.owner}"
  group = "${var.group}"
  costcenter = "${var.costcenter}"
  region = "${var.region}"
  zone = "${var.zone}"
  network = "${var.network}"
  subnet_id = "${var.public_subnet_id}"
  restricted_src_address = "${var.restricted_src_address}"
  ssh_key_public = "${file(var.public_key_path)}"
  image_id = "${var.image_id}"
  instance_type = "${var.instance_type}"
  registration_key = "${var.registration_key}"
  site_ssl_cert = "${file(var.site_ssl_cert)}"
  site_ssl_key = "${file(var.site_ssl_key)}"
  admin_username = "${var.admin_username}"
  admin_password = "${var.admin_password}"
  dns_server = "${var.dns_server}"
  ntp_server = "${var.ntp_server}"
  timezone   = "${var.timezone}"
  # vs_dns_name = "${var.vs_dns_name}"
  # vs_port = "${var.vs_port}"
  # pool_member_port = "${var.pool_member_port}"
  # pool_name = "${var.pool_name}"
}

output "sg_id" { value = "${module.my_proxy.sg_id}" }

output "instance_id" { value = "${module.my_proxy.instance_id}"  }
output "instance_private_ip" { value = "${module.my_proxy.instance_private_ip}" }
output "instance_public_ip" { value = "${module.my_proxy.instance_public_ip}" }



