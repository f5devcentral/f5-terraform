# vpc variable
variable cidr_block  { default = "10.0.0.0/24" }

# TAGS
variable environment    {}  # ex. "dev/prod"
variable owner          {}  # ex. "m.yoda"
variable group          {}  # ex. "marketing"
variable costcenter     {}  # ex. "4353"


# creates a VPC in AWS
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = true

  # metadata tagging
  tags {
    Name           = "${var.environment}_vpc"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
  }
}


output "vpc_id" { value = "${aws_vpc.vpc.id}" }