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

resource "azurerm_public_ip" "lb_pip" {
  name                = "az104-lbpip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"   
}

resource "azurerm_lb" "lb" {
  name                = "az104-lb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard" 

  frontend_ip_configuration {
    name                 = "az104-fe"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "be_pool" {
  name            = "az104-be"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "hp" {
  name                = "az104-hp"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = "az104-lbrule"
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = "az104-fe"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.be_pool.id]
  probe_id                       = azurerm_lb_probe.hp.id
  idle_timeout_in_minutes        = 4
  enable_tcp_reset               = false
  floating_ip_enabled            = false
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_assoc" {
  count                   = 2  
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig1" 
  backend_address_pool_id = azurerm_lb_backend_address_pool.be_pool.id
}

resource "azurerm_subnet" "appgw" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.3.224/27"]
}

resource "azurerm_public_ip" "gwpip" {
  name                = "az104-gwpip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1"]
}

resource "azurerm_application_gateway" "appgw" {
  name                = "az104-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
  
  autoscale_configuration {
    min_capacity = 2
    max_capacity = 3
  }
  enable_http2 = false
  zones = ["1"]

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = "appgw-fe-public"
    public_ip_address_id = azurerm_public_ip.gwpip.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  backend_address_pool {
    name = "az104-appgwbe"
    ip_addresses = [
      azurerm_network_interface.nic[1].private_ip_address, 
      azurerm_network_interface.nic[2].private_ip_address 
    ]
  }
  
  backend_address_pool {
    name = "az104-imagebe"
    ip_addresses = [
      azurerm_network_interface.nic[1].private_ip_address 
    ]
  }

  backend_address_pool {
    name = "az104-videobe"
    ip_addresses = [
      azurerm_network_interface.nic[2].private_ip_address 
    ]
  }

  backend_http_settings {
    name                  = "az104-http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "az104-listener"
    frontend_ip_configuration_name = "appgw-fe-public"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  url_path_map {
    name = "path-map-rules"
    default_backend_address_pool_name = "az104-appgwbe"
    default_backend_http_settings_name = "az104-http"
    path_rule {
      name  = "images"
      paths = ["/image/*"]
      backend_address_pool_name = "az104-imagebe"
      backend_http_settings_name = "az104-http"
    }
    path_rule {
      name  = "videos"
      paths = ["/video/*"]
      backend_address_pool_name = "az104-videobe"
      backend_http_settings_name = "az104-http"
    }
  }

  request_routing_rule {
    name               = "az104-gwrule"
    rule_type          = "PathBasedRouting"
    priority           = 10
    http_listener_name = "az104-listener"
    url_path_map_name  = "path-map-rules"
  }
}



