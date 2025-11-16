output "blob_direct_url" {
  description = "Direct link to file (should return 'ResourceNotFound' error)"
  value = azurerm_storage_blob.blob_upload.url
}

output "blob_sas_url" {
  description = "Link to file with SAS token (should open file)"
  value = "${azurerm_storage_blob.blob_upload.url}${data.azurerm_storage_account_sas.sas_token.sas}"
  sensitive = true 
}