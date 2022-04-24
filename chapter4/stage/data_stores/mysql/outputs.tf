output "mysql_fqdn" {
  description = "MySQL fully qualified domain name"
  value = azurerm_mysql_server.example.fqdn
}