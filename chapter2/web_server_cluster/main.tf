# The example below contains the bare minimum to provision a cluster of web
# servers on Azure. Similarly as in single web server case, the config is
# more verbose than the equivalent on AWS.

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

# Configure a VM scale set
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  admin_username                  = "exampleadmin"
  admin_password                  = var.vm_password
  disable_password_authentication = false # Use password auth instead of SSH keys
  instances                       = 2 # Default number of instances // TODO: Ignore this parameter for autoscaling
  location                        = azurerm_resource_group.example.location
  name                            = "example-linux-virtual-machine-scale-set"
  resource_group_name             = azurerm_resource_group.example.name
  sku                             = "Standard_B1ls" # Smallest VM for testing purposes

  network_interface {
    name    = "example-network-interface"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.example.id
      ]
    }
  }

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS" # Lowest storage tier
  }

  # Find available images in region with command 'az vm image list' eg.
  # az vm image list --publisher "Canonical" --offer "Ubuntu" --sku "20_04-lts" --location "UAE North" --all
  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("start_web_server.sh") # Base64 encoded startup script
}

# Configure a subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"] # Occupied part of the address space (10.0.0.0 - 10.0.0.255)
}

# Configure a virtual network
resource "azurerm_virtual_network" "example" {
  address_space       = ["10.0.0.0/16"] # Address spaces available for subnets (10.0.0.0 - 10.0.255.255)
  location            = azurerm_resource_group.example.location
  name                = "example-virtual-network"
  resource_group_name = azurerm_resource_group.example.name
}

# Configure a load balancer
resource "azurerm_lb" "example" {
  location            = azurerm_resource_group.example.location
  name                = "example-lb"
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Configure a public IP
resource "azurerm_public_ip" "example" {
  allocation_method   = "Dynamic"
  location            = azurerm_resource_group.example.location
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
}

# Configure a backend address pool
#
# This pool manages IPs that will be accessed by the load balancer.
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "example-backend-address-pool"
}

# Configure a load balancer rule
#
# This rule tells which ports should be used on load balancer and VMs.
resource "azurerm_lb_rule" "example" {
  backend_port                   = 8080 # Port of application on the VM
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  frontend_port                  = 80 # Port on which load balancer will receive requests
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "example-lb-rule"
  protocol                       = "Tcp"
  backend_address_pool_ids       = [
    azurerm_lb_backend_address_pool.example.id
  ]
}

# Output variables printed to the console after apply
output "lb_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.example.ip_address
}

// TODO: Autorepair (healthchecks)
// TODO: Autoscaling
