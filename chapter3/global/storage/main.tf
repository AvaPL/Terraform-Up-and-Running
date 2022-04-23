# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "example-resource-group"
    storage_account_name = "example241574"
    container_name       = "example-storage-container"
    key                  = "global/storage/terraform.tfstate"
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

# Configure Azure storage account
#
# Azure files have write locks and encryption by default
resource "azurerm_storage_account" "example" {
  account_replication_type = "LRS" # Locally redundant storage with 3 copies in local datacenter
  account_tier             = "Standard" # Lowest account tier
  location                 = azurerm_resource_group.example.location
  name                     = "example241574"
  resource_group_name      = azurerm_resource_group.example.name

  blob_properties {
    versioning_enabled = true # Keep history of states
  }

  lifecycle {
    prevent_destroy = true # Prevent destroying via 'terraform destroy'
  }
}

# Configure storage container for Terraform state
resource "azurerm_storage_container" "example" {
  name                  = "example-storage-container"
  storage_account_name  = azurerm_storage_account.example.name

  lifecycle {
    prevent_destroy = true # Prevent destroying via 'terraform destroy'
  }
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value = azurerm_storage_account.example.primary_blob_endpoint
}

output "storage_container_name" {
  description = "Storage container name"
  value = azurerm_storage_container.example.name
}