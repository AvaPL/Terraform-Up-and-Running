provider "azurerm" {
  features {}
}

module "app" {
  source         = "../../modules/app"
  environment    = "stag"
  server_message = "Hello, Another World!"
  vm_password    = var.vm_password
  vm_username    = var.vm_username
}