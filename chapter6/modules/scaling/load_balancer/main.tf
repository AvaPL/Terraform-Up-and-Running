# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure a load balancer
resource "azurerm_lb" "example" {
  location            = var.location
  name                = "${var.environment}-example-lb"
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Configure a public IP
resource "azurerm_public_ip" "example" {
  allocation_method   = "Dynamic"
  location            = var.location
  name                = "${var.environment}-example-public-ip"
  resource_group_name = var.resource_group_name
}
