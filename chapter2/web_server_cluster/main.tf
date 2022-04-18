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
  instances                       = 2 # Default number of instances
  location                        = azurerm_resource_group.example.location
  name                            = "example-linux-virtual-machine-scale-set"
  resource_group_name             = azurerm_resource_group.example.name
  sku                             = "Standard_B1ls" # Smallest VM for testing purposes

  network_interface {
    name    = "example-network-interface"
    primary = true

    ip_configuration {
      name                                   = "internal"
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

  custom_data = filebase64("start_web_server.sh") # Base64 encoded startup script

  # For some reason this currently does not enable self-healing
  # Question: https://docs.microsoft.com/en-us/answers/questions/815029/cannot-enable-autorepair-for-vm-scale-set.html
  automatic_instance_repair {
    enabled      = true
    grace_period = "PT10M"
  }

  health_probe_id = azurerm_lb_probe.example.id # Healthcheck used to determine if instance is healthy

  lifecycle {
    ignore_changes = [
      instances # Ignore instances count and let autoscaling control it after the initial deployment
    ]
  }
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
  probe_id                       = azurerm_lb_probe.example.id # Healthcheck used to determine if instance is healthy
}

# Configure a healthcheck probe
#
# This section is optional and in fact not needed to run the cluster.
# Its purpose is to provide a self-healing mechanism.
resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "example-lb-probe"
  port            = 8080
  protocol        = "Http"
  request_path    = "/"
}

# Configure autoscaling
#
# The configuration below scales based on total incoming bytes to easily test
# the scaling functionality. To increase the load manually, a simple command
# can be used:
# for n in {1..1000}; do curl http://<load balancer IP>; done
resource "azurerm_monitor_autoscale_setting" "example" {
  location            = azurerm_resource_group.example.location
  name                = "example-monitor-autoscale-setting"
  resource_group_name = azurerm_resource_group.example.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.example.id

  profile {
    name = "default"

    capacity {
      default = 2
      maximum = 10
      minimum = 1
    }

    rule {
      metric_trigger {
        metric_name        = "Network In Total" # Measure total incoming bytes
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
        operator           = "GreaterThan"
        statistic          = "Max" # Measure max total incoming bytes between VMs
        threshold          = 200000 # Trigger when the metric is over 100KB
        time_aggregation   = "Maximum" # Measure max total incoming bytes between time grains
        time_grain         = "PT1M" # Single measurement timeframe
        time_window        = "PT5M" # Measurement history length, in this case it will keep 5 time grains
      }

      scale_action {
        cooldown  = "PT5M" # How long should the rule wait before being applied again?
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Network In Total"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
        operator           = "LessThan"
        statistic          = "Max"
        threshold          = 100000
        time_aggregation   = "Maximum"
        time_grain         = "PT1M"
        time_window        = "PT5M"
      }

      scale_action {
        cooldown  = "PT5M"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
      }
    }
  }
}

# Output variables printed to the console after apply
output "lb_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.example.ip_address
}
