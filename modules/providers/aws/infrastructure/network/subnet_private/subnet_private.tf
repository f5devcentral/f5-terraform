# NOTE: Individual Subnet modules to enforce
# purpose & map_public_ip_on_launch

# private subnet variables
variable vpc_id            {}
variable cidr_block        {}
variable availability_zone {}
variable route_table_id    {}

# TAGS
variable environment    {}  # ex. "dev/prod"
variable owner          {}  # ex. "m.yoda"
variable group          {}  # ex. "marketing"
variable costcenter     {}  # ex. "4353"

# create a private subnet in an availability zone, associated with a private routing table
module "subnet_private" {
  source                  = "./../subnet"
  cidr_block              = "${var.cidr_block}"
  vpc_id                  = "${var.vpc_id}"
  availability_zone       = "${var.availability_zone}"
  environment             = "${var.environment}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  purpose                 = "private"
  map_public_ip_on_launch = "false"
}

# associate public routing table with subnet
resource "aws_route_table_association" "private_subnet_route_association" {
  subnet_id      = "${module.subnet_private.subnet_id}"
  route_table_id = "${var.route_table_id}"
}


output "private_subnet_id"       { value = "${module.subnet_private.subnet_id}" }
