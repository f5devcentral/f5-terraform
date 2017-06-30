### VARIABLES ###

# TAGS
variable application_dns  { default = "www.example.com" }  # ex. "www.example.com"
variable application      { default = "www"             }  # ex. "www" - short name used in object naming
variable environment      { default = "f5env"           }  # ex. dev/staging/prod
variable owner            { default = "f5owner"         }  
variable group            { default = "f5group"         }
variable costcenter       { default = "f5costcenter"    }  
variable purpose          { default = "public"          }  

# PLACEMENT
variable region         { default = "West US"         }
variable resource_group { default = "app.example.com" }

variable vnet_id        {}
variable subnet_id      {}
variable restricted_src_address { default = "0.0.0.0/0" }

# APPLICATION
variable docker_image         { default = "f5devcentral/f5-demo-app:azure" }

variable publisher            { default = "Canonical" }
variable offer                { default = "UbuntuServer" }
variable sku                  { default = "16.04.0-LTS" }
variable version              { default = "latest" }

variable instance_name_prefix { default = "appvm" }
variable instance_type        { default = "Standard_A0" }

variable admin_username {}
variable admin_password {}
variable ssh_key_public {}

# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }

# AUTOSCALE
variable scale_min      { default = 1 }
variable scale_max      { default = 3 }
variable scale_desired  { default = 1 }


# LB
# variable app_lb_name    {}

### PROVIDER ###

provider "azurerm" {
}

### RESOURCES ###

resource "azurerm_network_security_group" "sg" {
  # "Linux host name cannot exceed 64 characters in length or contain the following characters: 
  # ` ~ ! @ # $ % ^ & * ( ) = + _ [ ] { } \\ | ; : ' \" , < > / ?."
  name                = "${var.environment}-app-sg"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"

  security_rule {
    # "Resource name Management HTTPS is invalid. The name can be up to 80 characters long. It must begin with a word character, and it must end with a word character or with '_'. 
    # The name may contain word characters or '.', '-', '_'."
    name                       = "Management-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.restricted_src_address}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "${var.restricted_src_address}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.restricted_src_address}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
      Name           = "${var.environment}_${var.application}_app_sg"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }
}

# create public IP 
resource "azurerm_public_ip" "app_lb_public_ip" {
    name                          = "${var.environment}-app-lb-public-ip"
    location                      = "${var.region}"
    resource_group_name           = "${var.resource_group}"
    public_ip_address_allocation  = "dynamic"
    #domain_name_label             = "${var.resource_group}"

    tags {
        Name           = "${var.environment}_app_lb_public_ip"
        application    = "${var.application}"
        environment    = "${var.environment}"
        owner          = "${var.owner}"
        group          = "${var.group}"
        costcenter     = "${var.costcenter}"

    }
}


resource "azurerm_lb" "app_lb" {
  depends_on          = [ "azurerm_public_ip.app_lb_public_ip" ]
  name                = "${var.application}-${var.purpose}-lb"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.app_lb_public_ip.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = "${var.resource_group}"
  loadbalancer_id     = "${azurerm_lb.app_lb.id}"
  name                = "http-probe"
  port                = 80
  protocol            = "Http"
  request_path        = "/"
}



resource "azurerm_lb_backend_address_pool" "bpepool" {
  name                = "BackEndAddressPool"
  resource_group_name = "${var.resource_group}"
  loadbalancer_id     = "${azurerm_lb.app_lb.id}"

}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  count                          = "${var.scale_max}"
  resource_group_name            = "${var.resource_group}"
  name                           = "ssh"
  loadbalancer_id                 = "${azurerm_lb.app_lb.id}"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50200
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = "LBRule"
  resource_group_name            = "${var.resource_group}"
  loadbalancer_id                = "${azurerm_lb.app_lb.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  frontend_port                  = 80
  protocol                       = "Tcp"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.bpepool.id}"
  backend_port                   = 80
  probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
}

resource "random_id" "random_id" {
  byte_length = 1
}

resource "azurerm_storage_account" "storage_account" {
  # name can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  name                = "${var.environment}appstor${random_id.random_id.dec}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  account_type        = "Standard_LRS"

  tags {
      Name           = "${var.environment}_app_storage_account"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }
}

resource "azurerm_storage_container" "storage_container" {
  # only lowercase alphanumeric characters and hyphens allowed in "name"
  name                  = "${var.environment}-app-sc"
  resource_group_name   = "${var.resource_group}"
  storage_account_name  = "${azurerm_storage_account.storage_account.name}"
  container_access_type = "private"
}


data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    docker_image          = "${var.docker_image}"
  }
}


resource "azurerm_virtual_machine_scale_set" "app" {
  name                  = "${var.environment}-app-scaleset"
  depends_on            = [ "azurerm_lb.app_lb" ]
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group}"
  upgrade_policy_mode   = "Manual"

  sku {
    name     = "${var.instance_type}"
    tier     = "Standard"
    capacity = "${var.scale_desired}"
  }

  storage_profile_image_reference {
    publisher = "${var.publisher}"
    offer     = "${var.offer}"
    sku       = "${var.sku}"
    version   = "${var.version}"
  }

  # plan {
  #   name          = "${var.image_id}"
  #   publisher     = "XXXXX" 
  #   product       = "XXXXXXXXXXX"
  # }

  storage_profile_os_disk {
    name           = "osDiskProfile"
    caching        = "ReadWrite"
    create_option  = "FromImage"
    vhd_containers = ["${azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.storage_container.name}"]
  }

  # Managed Disks:
  # storage_profile_os_disk {
  #   name              = ""
  #   caching           = "ReadWrite"
  #   create_option     = "FromImage"
  #   managed_disk_type = "Standard_LRS"
  # }
  # storage_profile_data_disk {
  #     lun          = 0
  #   caching        = "ReadWrite"
  #   create_option  = "Empty"
  #   disk_size_gb   = 10 
  # }

  os_profile {
    computer_name_prefix  = "${var.environment}-${var.instance_name_prefix}"
    admin_username        = "${var.admin_username}"
    admin_password        = "${var.admin_password}"
    custom_data           = "${data.template_file.user_data.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.ssh_key_public}"
    }
  }

  network_profile {
    name    = "${var.environment}-App-NetworkProfile"
    primary = true

    ip_configuration {
      name      = "${var.environment}-App-Ip-Configuration"
      subnet_id = "${var.subnet_id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
      load_balancer_inbound_nat_rules_ids    = ["${element(azurerm_lb_nat_pool.lbnatpool.*.id, count.index)}"]
      # Doesn't exist yet
      #networkSecurityGroup = "${azurerm_network_security_group.sg.id}"
    }
  }

  tags {
    Name           = "${var.environment}-${var.application}-instance"
    application    = "${var.application}"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
  }
}


### OUTPUTS ###


output "sg_id" { value = "${azurerm_network_security_group.sg.id}" }
output "sg_name" { value = "${azurerm_network_security_group.sg.name}" }

output "lb_id" { value = "${azurerm_lb.app_lb.id}" }
output "lb_private_ip" { value = "${azurerm_lb.app_lb.private_ip_address}" }
output "lb_public_ip" { value = "${azurerm_public_ip.app_lb_public_ip.ip_address}" }


