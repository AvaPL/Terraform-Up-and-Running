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
    key                  = "prod/data_stores/mysql/terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Resource group remote state
data "terraform_remote_state" "resource_group" {
  backend = "azurerm"

  config = {
    resource_group_name  = "storage-resource-group"
    storage_account_name = "example241574"
    container_name       = "example-storage-container"
    key                  = "prod/resource_group/terraform.tfstate"
  }
}

resource "azurerm_mysql_server" "example" {
  location                     = data.terraform_remote_state.resource_group.outputs.resource_group_location
  name                         = "prod-example-mysql-server"
  resource_group_name          = data.terraform_remote_state.resource_group.outputs.resource_group_name
  sku_name                     = "B_Gen5_1" # Basic, generation 5, 1 CPU
  version                      = "8.0"
  ssl_enforcement_enabled      = true
  administrator_login          = "exampleadmin"
  administrator_login_password = var.mysql_password # Using var for password to keep the full config in this repo
}