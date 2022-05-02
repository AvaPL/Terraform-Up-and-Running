variable "environment" {
  description = "Environment"
  type        = string
}

variable "vm_password" {
  description = "Linux virtual machine root password"
  type        = string
  sensitive   = true
}

variable "server_message" {
  description = "Message shown on the main page"
  type = string
}