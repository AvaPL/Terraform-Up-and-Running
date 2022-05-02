# Output variables printed to the console after apply
output "lb_public_ip" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.example.ip_address
}
