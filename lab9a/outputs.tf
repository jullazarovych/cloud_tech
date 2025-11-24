output "production_url" {
  value = "https://${azurerm_linux_web_app.webapp.default_hostname}"
}
output "staging_url" {
  value = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
}