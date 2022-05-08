output "lb_id" {
  description = "Load balancer ID"
  value       = azurerm_lb.example.id
}

output "public_ip" {
  description = "Public IP"
  value       = azurerm_public_ip.example.ip_address
}