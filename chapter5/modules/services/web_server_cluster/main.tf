# The example below contains the bare minimum to provision a cluster of web
# servers on Azure with self-repair and autoscaling. Similarly as in single
# web server case, the config is more verbose than the equivalent on AWS.

# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Note: simplified remote states here so the example is not that complicated

# Configure a resource group
#
# All Azure resources have to be part of a resource group.
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "UAE North"
}

# Startup script template file
data "template_file" "start_web_server" {
  template = file("${path.module}/start_web_server.sh")

  vars = {
    port           = local.backend_port
    server_message = var.server_message
  }
}

locals {
  frontend_ip_configuration_name = "${var.environment}-example-frontend-ip"
  backend_port                   = 8080
}

# Configure a VM scale set
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  admin_username                  = "exampleadmin"
  admin_password                  = var.vm_password
  disable_password_authentication = false # Use password auth instead of SSH keys
  instances                       = 1 # Default number of instances
  location                        = azurerm_resource_group.example.location
  name                            = "${var.environment}-example-${sha1(data.template_file.start_web_server.rendered)}"
  # Change name on template change
  resource_group_name             = azurerm_resource_group.example.name
  sku                             = "Standard_B1ls" # Smallest VM for testing purposes

  network_interface {
    name    = "${var.environment}-example-network-interface"
    primary = true

    ip_configuration {
      name                                   = "${var.environment}-internal"
      primary                                = true
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

  custom_data = base64encode(data.template_file.start_web_server.rendered) # Base64 encoded startup script

  health_probe_id = azurerm_lb_probe.example.id # Healthcheck used to determine if instance is healthy

  lifecycle {
    create_before_destroy = true # Create a new instance before destroying the old one
  }
}

# Configure a subnet
resource "azurerm_subnet" "example" {
  name                 = "${var.environment}-example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"] # Occupied part of the address space (10.0.0.0 - 10.0.0.255)
}

# Configure a virtual network
resource "azurerm_virtual_network" "example" {
  address_space       = ["10.0.0.0/16"] # Address spaces available for subnets (10.0.0.0 - 10.0.255.255)
  location            = azurerm_resource_group.example.location
  name                = "${var.environment}-example-virtual-network"
  resource_group_name = azurerm_resource_group.example.name
}

# Configure a load balancer
resource "azurerm_lb" "example" {
  location            = azurerm_resource_group.example.location
  name                = "${var.environment}-example-lb"
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Configure a public IP
resource "azurerm_public_ip" "example" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.example.location
  name                = "${var.environment}-example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
}

# Configure a backend address pool
#
# This pool manages IPs that will be accessed by the load balancer.
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "${var.environment}-example-backend-address-pool"
}

# Configure a load balancer rule
#
# This rule tells which ports should be used on load balancer and VMs.
resource "azurerm_lb_rule" "example" {
  backend_port                   = local.backend_port # Port of application on the VM
  frontend_ip_configuration_name = local.frontend_ip_configuration_name
  frontend_port                  = 80 # Port on which load balancer will receive requests
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "${var.environment}-example-lb-rule"
  protocol                       = "Tcp"
  backend_address_pool_ids       = [
    azurerm_lb_backend_address_pool.example.id
  ]
  probe_id                       = azurerm_lb_probe.example.id # Healthcheck used to determine if instance is healthy
}

# Configure a healthcheck probe
#
# This section is optional and in fact not needed to run the cluster.
# Its purpose is to provide a self-healing mechanism.
resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "${var.environment}-example-lb-probe"
  port            = local.backend_port
  protocol        = "Http"
  request_path    = "/"
}

# Autoscaling removed for simplicity