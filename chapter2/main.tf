# The example below contains the bare minimum to provision a web server on Azure.
# It is more complex than the AWS one from the book, mostly due to networking
# verbose configuration with many required parameters that have no defaults.

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

# Configure example resource group
#
# All Azure resources have to be part of a resource group.
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "UAE North"
}

# Configure Azure VM
resource "azurerm_linux_virtual_machine" "example" {
  admin_username                  = "exampleadmin"
  # Use either interactive prompt or TF_VAR_<name> environment variable
  # or *.tfvars file. More about using variables for sensitive data:
  # https://learn.hashicorp.com/tutorials/terraform/sensitive-variables
  admin_password                  = var.vm_password
  disable_password_authentication = false # Use password auth instead of SSH keys
  location                        = azurerm_resource_group.example.location
  name                            = "example-linux-virtual-machine"
  network_interface_ids           = [
    # Azure VM has to have at least one network interface configured
    azurerm_network_interface.example.id
  ]
  resource_group_name             = azurerm_resource_group.example.name
  size                            = "Standard_B1ls" # Smallest VM for testing purposes

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

  custom_data = filebase64("start_busybox.sh") # Base64 encoded startup script
}

# Configure network interface
resource "azurerm_network_interface" "example" {
  location            = azurerm_resource_group.example.location
  name                = "example-network-interface"
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.example.id
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

# Configure subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"] # Occupied part of the address space (10.0.0.0 - 10.0.0.255)
}

# Configure virtual network
resource "azurerm_virtual_network" "example" {
  address_space       = ["10.0.0.0/16"] # Address spaces available for subnets (10.0.0.0 - 10.0.255.255)
  location            = azurerm_resource_group.example.location
  name                = "example-virtual-network"
  resource_group_name = azurerm_resource_group.example.name
}

# Configure public IP
resource "azurerm_public_ip" "example" {
  allocation_method   = "Dynamic"
  location            = azurerm_resource_group.example.location
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
}

# Configure network security group
resource "azurerm_network_security_group" "example" {
  location            = azurerm_resource_group.example.location
  name                = "example-network-security-group"
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "allow-inbound-traffic-on-port-8080"
    priority                   = 100 # Priority relative to other security rules if they overlap
    protocol                   = "Tcp"
    destination_address_prefix = "*" # To any IP
    destination_port_range     = "8080" # To port 8080 only
    source_address_prefix      = "*" # From any IP
    source_port_range          = "*" # From any port
  }
}

# Link subnet to security group
resource "azurerm_subnet_network_security_group_association" "example" {
  network_security_group_id = azurerm_network_security_group.example.id
  subnet_id                 = azurerm_subnet.example.id
}

# Output variables printed to console after apply
output "vm_public_ip" {
  description = "Public IP address of provisioned VM"
  value = azurerm_linux_virtual_machine.example.public_ip_address
}