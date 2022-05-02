provider "azurerm" {
  features {}
}

locals {
  environment = "stage"
}

module "web_server_cluster" {
  source         = "../../../../modules/services/web_server_cluster"
  environment    = local.environment
  vm_password    = var.vm_password
  server_message = "Hello, World!"
}
