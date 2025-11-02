resource "azurerm_resource_group" "rg" {
  name     = "az104-rg6"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "az104-06-vnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.60.0.0/22"]
}

resource "azurerm_subnet" "subnet" {
  count                = 3
  name                 = "subnet${count.index}" 
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = [cidrsubnet(tolist(azurerm_virtual_network.vnet.address_space)[0], 2, count.index)]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "az104-06-nsg1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  count               = 3
  name                = "az104-06-nic${count.index}" 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  count                     = 3
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
} 

resource "azurerm_windows_virtual_machine" "vm" {
  count                 = 3
  name                  = "az104-06-vm${count.index}" 
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size 
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  zone                  = null

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" 
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

locals {
  iis_base_script = "Install-WindowsFeature -name Web-Server -IncludeManagementTools; Start-Sleep -Seconds 30; remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' -ErrorAction SilentlyContinue; Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
  
  vm_scripts = [
    "powershell.exe -Command \"${local.iis_base_script}\"",
    "powershell.exe -Command \"${local.iis_base_script}; New-Item -Path 'c:\\inetpub\\wwwroot' -Name 'image' -Itemtype 'Directory' -ErrorAction SilentlyContinue; New-Item -Path 'c:\\inetpub\\wwwroot\\image\\' -Name 'iisstart.htm' -ItemType 'file' -ErrorAction SilentlyContinue; Add-Content -Path 'C:\\inetpub\\wwwroot\\image\\iisstart.htm' -Value $('Image from: ' + $env:computername)\"",
    "powershell.exe -Command \"${local.iis_base_script}; New-Item -Path 'c:\\inetpub\\wwwroot' -Name 'video' -Itemtype 'Directory' -ErrorAction SilentlyContinue; New-Item -Path 'c:\\inetpub\\wwwroot\\video\\' -Name 'iisstart.htm' -ItemType 'file' -ErrorAction SilentlyContinue; Add-Content -Path 'C:\\inetpub\\wwwroot\\video\\iisstart.htm' -Value $('Video from: ' + $env:computername)\""
  ]
}

resource "azurerm_virtual_machine_extension" "cse" {
  count                = 3
  name                 = "customScriptExtension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.7" 

  settings = jsonencode({
    "commandToExecute" = local.vm_scripts[count.index] 
  })
}