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

variable bigip_elb       {}

# SECURITY
variable ssh_key_name   {}
variable restricted_src_address { default = "0.0.0.0/0" }

variable admin_username {}
# variable admin_password {}


# APPLICATION
variable vs_port          { default = "443" }
variable pool_member_port { default = "80" }
variable pool_name        { default = "default" }  # DNS (ex. "www.example.com") used to create fqdn node if there's no Service Discovery iApp 
variable pool_tag_key     { default = "Name" }
variable pool_tag_value   { default = "dev-www-instance" }
variable policy_level     { default = "high"}

# AUTO SCALE 
variable scale_min                    { default = 2 }
variable scale_max                    { default = 8 }
variable scale_desired                { default = 2 }
variable scale_down_bytes_threshold   { default = "10000" }
variable scale_up_bytes_threshold     { default = "35000" }

variable notification_email           {}


### RESOURCES ###

resource "aws_cloudformation_stack" "bigip_stack" {
  # name must use "-" vs. "_". "StackName: Member must satisfy regular expression pattern: [a-zA-Z][-a-zA-Z0-9]"
  name = "${var.environment}-proxy-stack"
  capabilities = [ "CAPABILITY_IAM" ]
  timeout_in_minutes = 60
  parameters {
      deploymentName = "${var.deployment_name}"
      vpc = "${var.vpc_id}"
      availabilityZones = "${var.availability_zones}"
      subnets = "${var.subnet_ids}"
      restrictedSrcAddress = "${var.restricted_src_address}"
      bigipElasticLoadBalancer = "${var.bigip_elb}"
      sshKey = "${var.ssh_key_name}"
      instanceType = "${var.instance_type}"
      throughput = "${var.throughput}"
      adminUsername = "${var.admin_username}"
      managementGuiPort = "${var.management_gui_port}"
      timezone = "${var.timezone}"
      ntpServer = "${var.ntp_server}"
      scalingMinSize = "${var.scale_min}"
      scalingMaxSize = "${var.scale_max}"
      scaleDownBytesThreshold = "${var.scale_down_bytes_threshold}"
      scaleUpBytesThreshold = "${var.scale_up_bytes_threshold}"
      notificationEmail = "${var.notification_email}"
      virtualServicePort = "${var.vs_port}"
      applicationPort = "${var.pool_member_port}"
      appInternalDnsName = "${var.pool_name}"
      applicationPoolTagKey = "${var.pool_tag_key}"
      applicationPoolTagValue = "${var.pool_tag_value}"
      policyLevel = "${var.policy_level}"
      environment = "${var.environment}"
      application = "${var.application}"
      owner = "${var.owner}"
      group = "${var.group}"
      costcenter = "${var.costcenter}"
  }
  template_body = "${file("${path.module}/bigip.template")}"
  #template_url = "${var.template_url}"
}


### OUTPUTS ###

output "bigip_stack_id" { value = "${aws_cloudformation_stack.bigip_stack.id}" }
output "bigip_stack_outputs" { value = "${aws_cloudformation_stack.bigip_stack.outputs}" }
output "bigipAutoscaleGroup" { value = "${aws_cloudformation_stack.bigip_stack.outputs.bigipAutoscaleGroup}" }
output "s3Bucket" { value = "${aws_cloudformation_stack.bigip_stack.outputs.s3Bucket}" }


