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
