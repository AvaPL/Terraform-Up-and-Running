output "resource_group_location" {
  description = "Resource group location"
  value = azurerm_resource_group.example.location
}

output "resource_group_name" {
  description = "Resource group name"
  value = azurerm_resource_group.example.name
}
