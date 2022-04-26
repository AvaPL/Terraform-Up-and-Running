output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value = azurerm_storage_account.example.primary_blob_endpoint
}

output "storage_container_name" {
  description = "Storage container name"
  value = azurerm_storage_container.example.name
}
