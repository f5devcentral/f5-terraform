variable "public_key_path" {
  default = "~/.ssh/id_rsa_terraform.pub"
}

variable "key_name" {
  default = "terraform"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "us-east-1"
}

variable "availabilty_zone" {
  default = "us-east-1a"
} 

# F5 Networks Hourly BIGIP-12.1.1.1.0.196 - Better 25Mbps - built on Sep 07 20-6f7c56e1-c69f-4c47-9659-e26e27406220-ami-1d31460a.3 (ami-8f007b98)
variable "aws_amis" {
  default = {
    us-east-1 = "ami-8f007b98"
  }
}

variable "instance_type" {
  description = "AWS instance type"
  default = "m4.xlarge"
}
