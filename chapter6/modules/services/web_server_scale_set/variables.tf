variable "environment" {
  description = "Environment"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Virtual network location"
  type        = string
}

variable "server_message" {
  description = "Message shown on the main page"
  type        = string
}

variable "vm_username" {
  description = "Linux virtual machine root username"
  type        = string
  sensitive   = true
}

variable "vm_password" {
  description = "Linux virtual machine root password"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Scale set subnet ID"
  type        = string
}

variable "lb_id" {
  description = "Load balancer ID"
  type        = string
}

variable "frontend_ip_configuration_name" {
  description = "Frontend IP configuration name"
  type        = string
}
