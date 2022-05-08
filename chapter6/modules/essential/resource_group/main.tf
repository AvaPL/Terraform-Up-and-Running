# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure a resource group
#
# All Azure resources have to be part of a resource group.
resource "azurerm_resource_group" "example" {
  name     = "${var.environment}-example-resource-group"
  location = "UAE North"
}
