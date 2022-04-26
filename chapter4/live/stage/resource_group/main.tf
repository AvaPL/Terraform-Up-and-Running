# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "storage-resource-group"
    storage_account_name = "example241574"
    container_name       = "example-storage-container"
    key                  = "stage/resource_group/terraform.tfstate"
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
  name     = "stage-example-resource-group"
  location = "UAE North"
}
