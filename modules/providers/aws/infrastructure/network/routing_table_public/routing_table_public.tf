# NOTE: Individual Modules that determine if using 
# Internet Gateway or NAT Gateway

# routing table variables
variable vpc_id     {}
variable cidr_block {}
variable gateway_id {}

# TAGS
variable environment    {}  # ex. "dev/prod"
variable owner          {}  # ex. "m.yoda"
variable group          {}  # ex. "marketing"
variable costcenter     {}  # ex. "4353"


# create a private route table, to be included as part of private subnet modules
# and associated to a Internet gateway

resource "aws_route_table" "public_route_table" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "${var.cidr_block}"
    gateway_id = "${var.gateway_id}"
  }

  tags {
    Name        = "${var.environment}_public_routing_table"
    type           = "public"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
  }
}

output "public_route_table_id" { value = "${aws_route_table.public_route_table.id}" }