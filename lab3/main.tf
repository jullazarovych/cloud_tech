
resource "azurerm_resource_group" "rg3" {
  name     = "az104-rg3"
  location = "Poland Central"
}

resource "azurerm_managed_disk" "disk1" {
  name                 = "az104-disk1"
  location             = azurerm_resource_group.rg3.location
  resource_group_name  = azurerm_resource_group.rg3.name
  create_option        = "Empty"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 32

  tags = {
    deployment = "task1"
  }
}

resource "azurerm_managed_disk" "disk2" {
  name                 = "az104-disk2" 
  location             = azurerm_resource_group.rg3.location
  resource_group_name  = azurerm_resource_group.rg3.name
  create_option        = "Empty"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 32

  tags = {
    deployment = "task2"
  }
}
