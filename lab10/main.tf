resource "azurerm_resource_group" "rg" {
  name     = "az104-rg-region1"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "az104-10-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet0"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "az104-10-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "az104-nsg01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Правило: Дозволити RDP (порт 3389) для підключення до Windows
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "az104-10-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "az104-10-vm0"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s" 
  admin_username      = "localadmin"
  admin_password      = var.admin_password
  
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_recovery_services_vault" "vault" {
  name                = "az104-rsv-region1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  soft_delete_enabled = true 
}

resource "azurerm_backup_policy_vm" "policy" {
  name                = "az104-backup"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  timezone            = "UTC" 
  backup {
    frequency = "Daily"
    time      = "00:00" 
  }
  retention_daily {
    count = 30 
  }
  instant_restore_retention_days = 2
}

resource "azurerm_backup_protected_vm" "protection" {
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = azurerm_windows_virtual_machine.vm.id
  backup_policy_id    = azurerm_backup_policy_vm.policy.id
}

resource "azurerm_storage_account" "sa_monitor" {
  name                     = "az104sajuliala125"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
  name               = "Logs and Metrics to storage"
  target_resource_id = azurerm_recovery_services_vault.vault.id
  storage_account_id = azurerm_storage_account.sa_monitor.id

  enabled_log {
    category = "AzureBackupReport"
  }
  enabled_log {
    category = "CoreAzureBackup"
  }
  enabled_log {
    category = "AddonAzureBackupAlerts"
  }
  enabled_log {
    category = "AzureSiteRecoveryJobs"
  }
  enabled_log {
    category = "AzureSiteRecoveryEvents"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_storage_account" "sa_bootdiag" {
  name                     = "az104bootdiagjuliala125"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


resource "azurerm_resource_group" "rg_secondary" {
  name     = "az104-rg-region2"
  location = "North Europe" 
}

resource "azurerm_recovery_services_vault" "vault_secondary" {
  name                = "az104-rsv-region2"
  location            = azurerm_resource_group.rg_secondary.location
  resource_group_name = azurerm_resource_group.rg_secondary.name
  sku                 = "Standard" 
}

resource "azurerm_automation_account" "automation" {
  name                = "az104-auto-account"
  location            = "East US" # Змінено на East US, щоб уникнути конфлікту регіонів
  resource_group_name = azurerm_resource_group.rg_secondary.name
  sku_name            = "Basic"
}

resource "azurerm_virtual_network" "vnet_secondary" {
  name                = "az104-10-vnet-secondary"
  address_space       = ["10.11.0.0/16"]
  location            = azurerm_resource_group.rg_secondary.location
  resource_group_name = azurerm_resource_group.rg_secondary.name
}

resource "azurerm_subnet" "subnet_secondary" {
  name                 = "subnet0"
  resource_group_name  = azurerm_resource_group.rg_secondary.name
  virtual_network_name = azurerm_virtual_network.vnet_secondary.name
  address_prefixes     = ["10.11.0.0/24"]
}