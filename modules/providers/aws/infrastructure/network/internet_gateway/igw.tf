variable vpc_id { }

# TAGS

variable environment    {}  # ex. "dev/prod"
variable owner          {}  # ex. "m.yoda"
variable group          {}  # ex. "marketing"
variable costcenter     {}  # ex. "4353"


resource "aws_internet_gateway" "igw" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name        = "${var.environment}_igw"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
  }
}


output "igw_id" { value = "${aws_internet_gateway.igw.id}" }