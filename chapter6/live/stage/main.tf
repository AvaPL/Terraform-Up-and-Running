provider "azurerm" {
  features {}
}

module "app" {
  source         = "../../modules/app"
  environment    = "stage"
  server_message = "Hello, Staging World!"
  vm_password    = var.vm_password
  vm_username    = var.vm_username
}