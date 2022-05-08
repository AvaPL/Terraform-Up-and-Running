provider "azurerm" {
  features {}
}

module "app" {
  source         = "../../modules/app"
  environment    = "prod"
  server_message = "Hello, Production World!"
  vm_password    = var.vm_password
  vm_username    = var.vm_username
}