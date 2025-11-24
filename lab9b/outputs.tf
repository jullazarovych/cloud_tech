output "container_url" {
  value = "http://${azurerm_container_group.aci.fqdn}"
}