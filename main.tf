
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "Satellite_DR_RG" {
  name     = "satdevarmrgp001"
  location = "West US 2"
}

resource "azurerm_virtual_network" "Satellite_DR_VNET" {
  name                = "satdevarmvnet001"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Satellite_DR_RG.location
  resource_group_name = azurerm_resource_group.Satellite_DR_RG.name
}

resource "azurerm_subnet" "Satellite_DR_SUBNET" {
  name                 = "satdevarmsnet001"
  resource_group_name  = azurerm_resource_group.core_rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "app_nic" {
  name                = "nic-prod-weu-app-01"
  location            = azurerm_resource_group.core_rg.location
  resource_group_name = azurerm_resource_group.core_rg.name

  ip_configuration {
    name                          = "ipcfg-prod-weu-app-01"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "vm-prod-weu-app-01"
  resource_group_name = azurerm_resource_group.core_rg.name
  location            = azurerm_resource_group.core_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.app_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm"
    version   = "latest"
  }
}
