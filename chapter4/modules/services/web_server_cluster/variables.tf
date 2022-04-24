variable "storage_resource_group" {
  description = "Azure Storage resource group"
  type        = string
}

variable "storage_account_name" {
  description = "Azure Storage account name"
  type        = string
}

variable "storage_container_name" {
  description = "Azure Storage container name"
  type        = string
}

variable "storage_resource_group_state_key" {
  description = "Azure Storage resource group state key"
  type        = string
}

variable "storage_mysql_state_key" {
  description = "Azure Storage MySQL state key"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vm_password" {
  description = "Linux virtual machine root password"
  type        = string
  sensitive   = true
}
