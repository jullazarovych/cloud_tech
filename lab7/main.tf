data "http" "ip" {
  url = "https://api.ipify.org"
}

resource "azurerm_resource_group" "rg" {
  name     = "az104-rg7"
  location = "West Europe" 
}

resource "random_string" "unique" {
  length  = 16
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_storage_account" "storage" {
  name                     = "juliala125u0y" 
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS" 

  public_network_access_enabled = true

  network_rules {
    default_action             = "Deny"                   
    ip_rules                   = [data.http.ip.response_body] 
    bypass                     = ["AzureServices"]         
  }
  
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
  tags = {
    environment = "lab-az104"
  }
}

resource "azurerm_storage_management_policy" "lifecycle_rule" {
  storage_account_id = azurerm_storage_account.storage.id

  rule {
    name    = "Movetocool"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

resource "azurerm_storage_container" "data_container" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private" 
}

resource "azurerm_storage_container_immutability_policy" "data_policy" {
  storage_container_resource_manager_id = azurerm_storage_container.data_container.resource_manager_id
  immutability_period_in_days = 180  
}

resource "azurerm_storage_blob" "blob_upload" {
  name                   = "securitytest/cat.jpeg" 
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.data_container.name
  
  type                   = "Block"
  access_tier            = "Hot"   
  source                 = "cat.jpeg"
  depends_on = [
    azurerm_storage_container.data_container
  ]
}

data "azurerm_storage_account_sas" "sas_token" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  https_only        = true

  resource_types {
    object    = true
    container = false
    service   = false
  }

  services {
    blob  = true
    file  = false
    queue = false
    table = false
  }

  permissions {
    read    = true  
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false 
    filter  = false 
  }

  start  = timeadd(timestamp(), "-24h") 
  expiry = timeadd(timestamp(), "24h")  
}

resource "azurerm_storage_share" "file_share" {
  name                 = "share1"
  storage_account_id   = azurerm_storage_account.storage.id
  quota                = 1
}

resource "null_resource" "upload_file_workaround" {
  depends_on = [
    azurerm_storage_share.file_share
  ]
  provisioner "local-exec" {
    command = "az storage file upload --share-name ${azurerm_storage_share.file_share.name} --source cat.jpeg --path file-from-terraform.txt"
    environment = {
      AZURE_STORAGE_ACCOUNT = azurerm_storage_account.storage.name
      AZURE_STORAGE_KEY     = azurerm_storage_account.storage.primary_access_key
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints    = ["Microsoft.Storage"]
}