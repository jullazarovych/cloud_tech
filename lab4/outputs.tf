output "public_dns_zone_name_servers" {
  description = "Nameservers for the public zone contoso-ylaz.com."
  value       = azurerm_dns_zone.public_zone.name_servers
}