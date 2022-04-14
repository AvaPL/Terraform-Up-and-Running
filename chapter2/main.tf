# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Configure example resource group
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "UAE North"
}

resource "azurerm_linux_virtual_machine" "example" {
  admin_username        = "root"
  location              = azurerm_resource_group.example.location
  name                  = "example-machine"
  network_interface_ids = [] // TODO: Add network interface
  resource_group_name   = azurerm_resource_group.example.name
  size                  = "B1ls"
  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }
  // TODO: Add a script that starts a web server
}