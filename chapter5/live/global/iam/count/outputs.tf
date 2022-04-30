output "all_principal_ids" {
  description = "All principal IDs"
  value = azurerm_user_assigned_identity.example[*].principal_id
}