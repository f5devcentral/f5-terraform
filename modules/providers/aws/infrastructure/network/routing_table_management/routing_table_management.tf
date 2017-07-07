# NOTE: Individual Modules that determine if using 
# Internet Gateway or NAT Gateway

# routing table variables
variable vpc_id         {}
variable cidr_block     {}
variable nat_gateway_id {}

# TAGS
variable environment    {}  # ex. "dev/prod"
variable owner          {}  # ex. "m.yoda"
variable group          {}  # ex. "marketing"
variable costcenter     {}  # ex. "4353"


# create a management route table, to be included as part of management subnet modules
# and associated to a NAT gateway
resource "aws_route_table" "management_route_table" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block     = "${var.cidr_block}"
    nat_gateway_id = "${var.nat_gateway_id}"
  }

  tags {
    Name        = "${var.environment}-management-routing-table"
    purpose        = "management"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
  }
}

output "management_route_table_id" { value = "${aws_route_table.management_route_table.id}" }