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

# Configure a resource group
#
# All Azure resources have to be part of a resource group.
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "UAE North"
}

resource "azurerm_user_assigned_identity" "example" {
  for_each            = toset(var.user_names) # Create resource for each user name from the set
  location            = azurerm_resource_group.example.location
  name                = each.value # Use value from the set as identity name
  resource_group_name = azurerm_resource_group.example.name
}