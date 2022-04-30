output "all_identities" {
  description = "All identities"
  value = azurerm_user_assigned_identity.example
}

output "all_principal_ids" {
  description = "All principal IDs"
  value = values(azurerm_user_assigned_identity.example)[*].principal_id
}
