provider "azurerm" {
  features {}
}

module "web_server_cluster" {
  source = "../../../modules/services/web_server_cluster"
  storage_resource_group = "storage-resource-group"
  storage_account_name = "example241574"
  storage_container_name = "example-storage-container"
  storage_resource_group_state_key = "stage/resource_group/terraform.tfstate"
  storage_mysql_state_key = "stage/data_stores/mysql/terraform.tfstate"
  vm_password = var.vm_password
}
