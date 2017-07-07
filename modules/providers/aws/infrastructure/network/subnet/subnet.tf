# subnet variables
variable vpc_id                  {}
variable cidr_block              {}
variable map_public_ip_on_launch {}
variable availability_zone       {}


# TAGS
variable purpose        {}  # ex. "public/private"
variable environment    {}  # ex. "dev/prod"
variable owner          {}  # ex. "m.yoda"
variable group          {}  # ex. "marketing"
variable costcenter     {}  # ex. "4353"


# create a subnet, to be included as part of private/public subnet modules
resource "aws_subnet" "subnet" {
  cidr_block              = "${var.cidr_block}"
  vpc_id                  = "${var.vpc_id}"
  availability_zone       = "${var.availability_zone}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags {
    Name           = "${var.environment}-${var.purpose}-subnet-zone-${var.availability_zone}"
    purpose        = "${var.purpose}"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
  }
}


output "subnet_id" { value = "${aws_subnet.subnet.id}" }