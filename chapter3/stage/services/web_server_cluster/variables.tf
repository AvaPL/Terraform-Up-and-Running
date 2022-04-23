variable "vm_password" {
  description = "Linux virtual machine root password"
  type        = string
  sensitive   = true
}

variable "frontend_ip_configuration_name" {
  description = "Frontend IP configuration name referenced by the load balancer"
  type = string
  default = "example-frontend-ip"
}
