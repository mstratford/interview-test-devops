# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

# We want to use UK South zone for Azure.
variable "location" {
  type = string
  default = "uksouth"
}

variable "admin_username" {
    type = string
    description = "Administrator user name for virtual machine"
    default = "demouser"
}

variable "admin_password" {
    type = string
    description = "Password must meet Azure complexity requirements"
    default = "demopass123#"

}

# All of the resources we manage are in this resource group.
resource "azurerm_resource_group" "rg" {
  name     = "demo_resource_group"
  location = var.location
}

# Create a virtual network for our VMs.
resource "azurerm_virtual_network" "vnet" {
    name                = "demo_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "demo_vnet_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP for our first VM.
resource "azurerm_public_ip" "ip1" {
  name                = "demo_public_ip1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}
# Create public IP for our second VM.
resource "azurerm_public_ip" "ip2" {
  name                = "demo_public_ip2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}



# VM1 - Proxy webhost

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "vm1_nic"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm_nic_conf"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.ip1.id
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "vm1"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "vm1Disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Hold the public IP of VM1 as it gets set after creation. Used for the install-vm resource.
data "azurerm_public_ip" "ip1" {
  name                = azurerm_public_ip.ip1.name
  resource_group_name = azurerm_virtual_machine.vm.resource_group_name
  depends_on          = [azurerm_virtual_machine.vm]
}

# Install procedure for VM1, null resource required because Azure doesn't confirm public IP before completing.
resource "null_resource" "install-vm" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    ids = "data.azurerm_public_ip.ip1.ip_address"
  }

  # Copies the myapp.conf file to /etc/myapp.conf
  provisioner "file" {
    source      = "nginx-config"
    destination = "/tmp/nginx-config"

    connection {
      user     = var.admin_username
      password = var.admin_password
      host = data.azurerm_public_ip.ip1.ip_address # <-- note here we're using the Data Source rather than the Resource for a Public IP
    }
  }

  provisioner "local-exec" {
    command = "echo VM1 IP: ${data.azurerm_public_ip.ip1.ip_address} >> public_ips.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.admin_password} | sudo -S apt update",
      "sudo apt install -y nginx",
      "sudo mv /tmp/nginx-config /etc/nginx/sites-enabled/default",
      "sudo service nginx restart"
    ]
    connection {
      user     = var.admin_username
      password = var.admin_password
      host = data.azurerm_public_ip.ip1.ip_address # <-- note here we're using the Data Source rather than the Resource for a Public IP
    }
  }
}




# VM2 - Backend Private Web Host


# Create network interface
resource "azurerm_network_interface" "nic2" {
  name                      = "vm2_nic"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm_nic_conf"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.11"
    public_ip_address_id          = azurerm_public_ip.ip2.id
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm2" {
  name                  = "vm2"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "vm2Disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "vm2"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

# Hold the public IP of VM1 as it gets set after creation. Used for the install-vm resource.
data "azurerm_public_ip" "ip2" {
  name                = azurerm_public_ip.ip2.name
  resource_group_name = azurerm_virtual_machine.vm2.resource_group_name
  depends_on          = [azurerm_virtual_machine.vm2]
}

# Install procedure for VM2, null resource required because Azure doesn't confirm public IP before completing.
resource "null_resource" "install-vm2" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    ids = "data.azurerm_public_ip.ip2.ip_address"
  }

  provisioner "local-exec" {
    command = "echo VM2 IP: ${data.azurerm_public_ip.ip2.ip_address} >> public_ips.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.admin_password} | sudo -S apt update",
      "sudo apt install -y python3 python3-venv git make gunicorn",
      "git clone https://github.com/mstratford/Artistics.git",
      "cd Artistics",
      "make install",
      "nohup ./run.sh &",
      "sleep 1"
    ]
    connection {
      user     = var.admin_username
      password = var.admin_password
      host = data.azurerm_public_ip.ip2.ip_address # <-- note here we're using the Data Source rather than the Resource for a Public IP
    }
  }
}
