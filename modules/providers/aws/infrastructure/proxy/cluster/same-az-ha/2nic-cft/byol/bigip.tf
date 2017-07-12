# CREATES 2 SECURITY GROUPS + SAME AZ CLUSTER OF 2NIC BIG-IPs

### VARIABLES ###

variable template_url { default = "https://s3.amazonaws.com/f5-cft/f5-existing-stack-same-az-cluster-byol-2nic-bigip.template" }

# TAGS
variable purpose        { default = "public"       }  
variable environment    { default = "dev"          }  
variable application    { default = "f5app"        }  
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      } 
variable costcenter     { default = "f5costcenter" } 


# NETWORK:
variable region                   { default = "us-west-2"  }
variable vpc_id                   {}
variable management_subnet_id     {}
variable public_subnet_id         {}

# SECURITY GROUPS
variable management_sg_id     {}
variable public_sg_id         {}

# SYSTEM
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
variable management_gui_port  { default = "443" }

# PROXY:
variable instance_type  { default = "m4.2xlarge" }
variable image_name     { default = "Best"       }  # ex. "Good, Better or Best"


# SECURITY
variable ssh_key_name           {}  # example "my-terraform-key"
variable restricted_src_address { default = "0.0.0.0/0" }

# LICENSE
variable license_key_1 {}  # ex. "XXXXX-XXXXX-XXXXX-XXXXX-XXXXXXX"
variable license_key_2 {}


### RESOURCES ###

resource "aws_cloudformation_stack" "bigip_stack" {
  name = "${var.environment}-proxy-stack"
  # name must use "-" vs. "_". "StackName: Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]"
  capabilities = [ "CAPABILITY_IAM" ]
  parameters {
    Vpc                          = "${var.vpc_id}"
    managementSubnetAz1          = "${var.management_subnet_id}"
    subnet1Az1                   = "${var.public_subnet_id}"
    bigipManagementSecurityGroup = "${var.management_sg_id}" 
    bigipExternalSecurityGroup   = "${var.public_sg_id}"
    imageName                    = "${var.image_name}"
    instanceType                 = "${var.instance_type}"
    sshKey                       = "${var.ssh_key_name}"
    environment                  = "${var.environment}"
    application                  = "${var.application}"
    owner                        = "${var.owner}"
    group                        = "${var.group}"
    costcenter                   = "${var.costcenter}"
    licenseKey1                  = "${var.license_key_1}"
    licenseKey2                  = "${var.license_key_2}"
  }
  template_body = "${file("${path.module}/bigip.template")}"
  #template_url = "${var.template_url}"
}


### OUTPUTS ###

output "bigip_stack_id" { value = "${aws_cloudformation_stack.bigip_stack.id}" }
output "bigip_stack_outputs" { value = "${aws_cloudformation_stack.bigip_stack.outputs}" }

output "Bigip1ExternalInterfacePrivateIp" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1ExternalInterfacePrivateIp}" }
output "Bigip1InstanceId" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1InstanceId}" }
output "Bigip1ManagementEipAddress" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1ManagementEipAddress}" }
output "Bigip1ManagementInterface" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1ManagementEipAddress}" }
output "Bigip1ManagementInterfacePrivateIp" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1ManagementInterfacePrivateIp}" }
output "Bigip1Url" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1Url}" }
output "Bigip1VipEipAddress" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1VipEipAddress}" }
output "Bigip1VipPrivateIp" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1VipPrivateIp}" }
output "Bigip1subnet1Az1Interface" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1subnet1Az1Interface}" }
output "Bigip1subnet1Az1SelfEipAddress" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip1subnet1Az1SelfEipAddress}" }


output "Bigip2ExternalInterfacePrivateIp" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2ExternalInterfacePrivateIp}" }
output "Bigip2InstanceId" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2InstanceId}" }
output "Bigip2ManagementEipAddress" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2ManagementEipAddress}" }
output "Bigip2ManagementInterface" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2ManagementEipAddress}" }
output "Bigip2ManagementInterfacePrivateIp" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2ManagementInterfacePrivateIp}" }
output "Bigip2Url" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2Url}" }
output "Bigip2subnet1Az1Interface" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2subnet1Az1Interface}" }
output "Bigip2subnet1Az1SelfEipAddress" { value = "${aws_cloudformation_stack.bigip_stack.outputs.Bigip2subnet1Az1SelfEipAddress}" }










