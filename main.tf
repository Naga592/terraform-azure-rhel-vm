provider "azurerm" {
  features {}
}

# -------------------------------
# Inputs
# -------------------------------
variable "vm_name" {}
variable "vm_size" {}
variable "admin_username" {}
variable "admin_password" {}

# -------------------------------
# Existing Resource Group
# -------------------------------
data "azurerm_resource_group" "rg" {
  name = "NAGA-IACHYBRID-DEV"
}

# -------------------------------
# Existing VNet
# -------------------------------
data "azurerm_virtual_network" "vnet" {
  name                = "sntdevarmvntuw2222"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# -------------------------------
# Existing Subnet
# -------------------------------
data "azurerm_subnet" "subnet" {
  name                 = "iacdevarmsubuw4444"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

# -------------------------------
# Existing NSG
# -------------------------------
data "azurerm_network_security_group" "nsg" {
  name                = "iacdevarmnsguw2222"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# -------------------------------
# Existing Route Table
# -------------------------------
data "azurerm_route_table" "rt" {
  name                = "sntdevarmrotuw4444"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# -------------------------------
# NIC (No Public IP)
# -------------------------------
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = "West US 2"
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Attach NSG to NIC
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = data.azurerm_network_security_group.nsg.id
}

# -------------------------------
# VM (RHEL 9.4)
# -------------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = "West US 2"
  resource_group_name = data.azurerm_resource_group.rg.name
  size                = var.vm_size

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_username = var.admin_username
  admin_password = var.admin_password
  disable_password_authentication = false

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9_4"
    version   = "latest"
  }

  computer_name = var.vm_name

  tags = {
    environment = "dev"
  }
}

