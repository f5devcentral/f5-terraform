### VARIABLES ###

# TAGS
variable purpose        { default = "public"       }  
variable environment    { default = "f5env"        }  #ex. dev/staging/prod
variable owner          { default = "f5owner"      }  
variable group          { default = "f5group"      } 
variable costcenter     { default = "f5costcenter" } 
variable application    { default = "f5app"        }  

# PLACEMENT
variable region         { default = "West US"         }
variable location       { default = "westus"          } 
variable resource_group { default = "app.example.com" }

variable vnet_id        {}
variable subnet_id      {}

# PROXY
variable image_id       {}
variable instance_type  { default = "Standard_D3_v2" }
variable bigip_version  { default = "13.0.021"       }

# SYSTEM
variable instance_name        { default = "f5vm01"            }
variable dns_server           { default = "8.8.8.8"           }
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC"               }
variable management_gui_port  { default = "8443"              }

# SECURITY
variable admin_username {}
variable admin_password {}

variable ssh_key_public {}
variable ssh_key_name   {}
variable restricted_src_address { default = "0.0.0.0/0" }

# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }

# APPLICATION
variable vs_dns_name      { default = "www.example.com" }
variable vs_address       { default = "0.0.0.0" }
variable vs_mask          { default = "0.0.0.0" }
variable vs_port          { default = "443" }

# SERVICE DISCOVERY
variable pool_member_port { default = "80" }
variable pool_name        { default = "www.example.com" }  # DNS (ex. "www.example.com") used to create fqdn node if there's no Service Discovery iApp 
variable pool_tag_key     { default = "Name" }
variable pool_tag_value   { default = "dev-demo-instance" }

variable azure_subscription_id  { default = "none" }
variable azure_tenant_id        { default = "none" }
variable azure_resource_group   { default = "none" }
variable azure_client_id        { default = "none" }
variable azure_sp_secret        { default = "none" }


# LICENSE
variable registration_key {}


### RESOURCES ###

resource "azurerm_network_security_group" "sg" {
  # "Linux host name cannot exceed 64 characters in length or contain the following characters: 
  # ` ~ ! @ # $ % ^ & * ( ) = + _ [ ] { } \\ | ; : ' \" , < > / ?."
  name                = "${var.environment}-proxy-sg"
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
    name                       = "Management-HTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "${var.restricted_src_address}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Virtual-HTTPS"
    priority                   = 102
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
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
      Name           = "${var.environment}_proxy_sg"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }
}

# create public IP FOR INITIAL ACCESS
resource "azurerm_public_ip" "public_ip" {
    name = "${var.environment}-proxy-public-ip"
    location = "${var.region}"
    resource_group_name = "${var.resource_group}"
    public_ip_address_allocation = "dynamic"

    tags {
        Name           = "${var.environment}_proxy_public_ip"
        environment    = "${var.environment}"
        owner          = "${var.owner}"
        group          = "${var.group}"
        costcenter     = "${var.costcenter}"
        application    = "${var.application}"
    }
}

resource "azurerm_network_interface" "proxy_int" {
  name                = "${var.environment}-proxy-int"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  network_security_group_id = "${azurerm_network_security_group.sg.id}"

  ip_configuration {
      name = "${var.environment}-proxy-public-ip-conf"
      subnet_id = "${var.subnet_id}"
      private_ip_address_allocation = "dynamic"
      private_ip_address = "dynamic"
      public_ip_address_id = "${azurerm_public_ip.public_ip.id}"
  }

}

resource "random_id" "random_id" {
  byte_length = 1
}

resource "azurerm_storage_account" "storage_account" {
  # name can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  name                = "${var.environment}proxystor${random_id.random_id.dec}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  account_type        = "Standard_LRS"

  tags {
      Name           = "${var.environment}_proxy_storage_account"
      environment    = "${var.environment}"
      owner          = "${var.owner}"
      group          = "${var.group}"
      costcenter     = "${var.costcenter}"
      application    = "${var.application}"
  }
}

resource "azurerm_storage_container" "storage_container" {
  # only lowercase alphanumeric characters and hyphens allowed in "name"
  name                  = "${var.environment}-proxy-sc"
  resource_group_name   = "${var.resource_group}"
  storage_account_name  = "${azurerm_storage_account.storage_account.name}"
  container_access_type = "private"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    admin_username        = "${var.admin_username}"
    admin_password        = "${var.admin_password}"
    hostname              = "${var.instance_name}.${var.location}.cloudapp.azure.com"
    management_gui_port   = "${var.management_gui_port}"
    dns_server            = "${var.dns_server}"
    ntp_server            = "${var.ntp_server}"
    timezone              = "${var.timezone}"
    region                = "${var.region}"
    application           = "${var.application}"
    site_ssl_cert         = "${var.site_ssl_cert}"
    site_ssl_key          = "${var.site_ssl_key}"
    vs_dns_name           = "${var.vs_dns_name}"
    vs_address            = "${var.vs_address}"
    vs_mask               = "${var.vs_mask}"
    vs_port               = "${var.vs_port}"
    pool_member_port      = "${var.pool_member_port}"
    pool_name             = "${var.pool_name}"
    pool_tag_key          = "${var.pool_tag_key}"
    pool_tag_value        = "${var.pool_tag_value}"
    azure_subscription_id = "${var.azure_subscription_id}"
    azure_tenant_id       = "${var.azure_tenant_id }"
    azure_resource_group  = "${var.azure_resource_group}"
    azure_client_id       = "${var.azure_client_id}"
    azure_sp_secret       = "${var.azure_sp_secret}"
    registration_key      = "${var.registration_key}"
  }
}


resource "azurerm_virtual_machine" "bigip" {
  name                  = "${var.environment}-proxy"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group}"
  network_interface_ids = ["${azurerm_network_interface.proxy_int.id}"]
  vm_size               = "${var.instance_type}"

  storage_image_reference {
    publisher = "f5-networks"                
    offer     = "f5-big-ip-hourly"
    sku       = "${var.image_id}"
    version   = "${var.bigip_version}"
  }

  storage_os_disk {
    name          = "${var.instance_name}-osdisk1"
    vhd_uri       = "${azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.storage_container.name}/${var.instance_name}.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.environment}-${var.instance_name}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${data.template_file.user_data.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${var.ssh_key_public}"
    }
  }

  plan {
    name          = "${var.image_id}"
    publisher     = "f5-networks" 
    product       = "f5-big-ip-hourly"
  }

  tags {
    Name           = "${var.environment}_proxy"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}


resource "azurerm_virtual_machine_extension" "run_startup_cmd" {
  name                 = "${var.environment}-proxy-run-startup-cmd"
  location             = "${var.region}"
  resource_group_name  = "${var.resource_group}"
  virtual_machine_name = "${azurerm_virtual_machine.bigip.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"  
  # publisher            = "Microsoft.Azure.Extensions"
  # type                 = "CustomScript"
  # type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash -c \"base64 -d /var/lib/waagent/CustomData | bash\""
    }
  SETTINGS

  tags {
    Name           = "${var.environment}_proxy"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}


### OUTPUTS ###


output "sg_id" { value = "${azurerm_network_security_group.sg.id}" }
output "sg_name" { value = "${azurerm_network_security_group.sg.name}" }

output "instance_id" { value = "${azurerm_virtual_machine.bigip.id}"  }
output "instance_private_ip" { value = "${azurerm_network_interface.proxy_int.private_ip_address}" }


output "instance_public_ip" { value = "${azurerm_public_ip.public_ip.ip_address}" }

