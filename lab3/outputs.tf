output "resource_group" {
  value = azurerm_resource_group.rg3.name
}

output "disk2_location" {
  value = azurerm_managed_disk.disk2.location
}

output "disk3_name" {
  value = azurerm_managed_disk.disk3.name
}

output "cloudshell_storage_account" {
  value = azurerm_storage_account.cloudshell.name
}

output "cloudshell_file_share" {
  value = azurerm_storage_share.cloudshell_share.name
}

output "disk4_name" {
  value = azurerm_managed_disk.disk4.name
}
