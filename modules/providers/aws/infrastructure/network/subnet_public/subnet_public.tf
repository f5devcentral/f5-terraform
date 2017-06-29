# NOTE: Individual Subnet modules to enforce
# purpose & map_public_ip_on_launch

# public subnet variables
variable vpc_id            {}
variable cidr_block        {}
variable availability_zone {}
variable route_table_id    {}

# TAGS
variable environment    {}  # ex. "dev/prod"
variable owner          {}  # ex. "m.yoda"
variable group          {}  # ex. "marketing"
variable costcenter     {}  # ex. "4353"

# create a public subnet in an availability zone, associated with IGW & routing table
module "subnet_public" {
  source                  = "./../subnet"
  cidr_block              = "${var.cidr_block}"
  vpc_id                  = "${var.vpc_id}"
  availability_zone       = "${var.availability_zone}"
  environment             = "${var.environment}"
  owner                   = "${var.owner}"
  group                   = "${var.group}"
  costcenter              = "${var.costcenter}"
  purpose                 = "public"
  map_public_ip_on_launch = "true"
}

# associate public routing table with subnet
resource "aws_route_table_association" "public_subnet_route_association" {
  subnet_id      = "${module.subnet_public.subnet_id}"
  route_table_id = "${var.route_table_id}"
}


output "public_subnet_id" { value = "${module.subnet_public.subnet_id}" }