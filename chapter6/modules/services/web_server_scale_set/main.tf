# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

locals {
  backend_port  = 8080
  frontend_port = 80
}

# Startup script template file
data "template_file" "start_web_server" {
  template = file("${path.module}/start_web_server.sh")

  vars = {
    port           = local.backend_port
    server_message = var.server_message
  }
}

# Configure a VM scale set
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  admin_username                  = var.vm_username
  admin_password                  = var.vm_password
  disable_password_authentication = false # Use password auth instead of SSH keys
  instances                       = 1 # Default number of instances
  location                        = var.location
  name                            = "${var.environment}-example-scale-set-${md5(data.template_file.start_web_server.rendered)}"
  resource_group_name             = var.resource_group_name
  sku                             = "Standard_B1ls" # Smallest VM for testing purposes

  network_interface {
    name    = "${var.environment}-network-interface"
    primary = true

    ip_configuration {
      name                                   = "${var.environment}-ip-configuration"
      primary                                = true
      subnet_id                              = var.subnet_id
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

  automatic_instance_repair {
    enabled      = true
    grace_period = "PT10M"
  }

  health_probe_id = azurerm_lb_probe.example.id # Healthcheck used to determine if instance is healthy

  # Zero-downtime deployment not included for simplicity
}

# Configure a backend address pool
#
# This pool manages IPs that will be accessed by the load balancer.
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = var.lb_id
  name            = "${var.environment}-example-backend-pool"
}

# Configure a healthcheck probe
#
# This section is optional and in fact not needed to run the cluster.
# Its purpose is to provide a self-healing mechanism.
resource "azurerm_lb_probe" "example" {
  loadbalancer_id = var.lb_id
  name            = "${var.environment}-example-lb-probe"
  port            = local.backend_port
  protocol        = "Http"
  request_path    = "/"
}

# Configure a load balancer rule
#
# This rule tells which ports should be used on load balancer and VMs.
resource "azurerm_lb_rule" "example" {
  backend_port                   = local.backend_port # Port of application on the VM
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  frontend_port                  = local.frontend_port
  loadbalancer_id                = var.lb_id
  name                           = "${var.environment}-example-lb-rule"
  protocol                       = "Tcp"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.example.id # Healthcheck used to determine if instance is healthy
}
