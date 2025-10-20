
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

resource "azurerm_storage_account" "cloudshell" {
  name                     = "az104cloudshellsa123"
  resource_group_name      = azurerm_resource_group.rg3.name
  location                 = azurerm_resource_group.rg3.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    purpose = "cloudshell-storage"
  }
}

resource "azurerm_storage_share" "cloudshell_share" {
  name                 = "fs-cloudshell"
  storage_account_name = azurerm_storage_account.cloudshell.name
  quota                = 50
}

resource "azurerm_managed_disk" "disk3" {
  name                 = "az104-disk3"
  location             = azurerm_resource_group.rg3.location
  resource_group_name  = azurerm_resource_group.rg3.name
  create_option        = "Empty"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 32

  tags = {
    deployment = "task3-terraform"
  }
}

resource "azurerm_managed_disk" "disk4" {
  name                 = "az104-disk4"
  location             = azurerm_resource_group.rg3.location
  resource_group_name  = azurerm_resource_group.rg3.name
  create_option        = "Empty"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 32

  tags = {
    deployment = "task4-cli-terraform"
  }
}
resource "null_resource" "deploy_bicep_disk5" {
  depends_on = [azurerm_resource_group.rg3]

  provisioner "local-exec" {
    command = "az deployment group create --resource-group ${azurerm_resource_group.rg3.name} --template-file azuredeploydisk.bicep --parameters managedDiskName=az104-disk5 skuName=StandardSSD_LRS diskSizeinGiB=32"
  }
}