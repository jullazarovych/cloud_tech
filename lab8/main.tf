resource "azurerm_resource_group" "rg" {
  name     = "az104-rg8"
  location = "Poland Central"
}
resource "azurerm_virtual_network" "vmss_vnet" {
  name                = "vmss-vnet"
  address_space       = ["10.82.0.0/20"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "subnet0"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.82.0.0/24"]
}

resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "vmss1-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "lb_pip" {
  name                = "vmss-lb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" 
}

resource "azurerm_lb" "vmss_lb" {
  name                = "vmss-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "vmss-backend-pool"
}

resource "azurerm_lb_probe" "vmss_probe" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "http-probe"
  port            = 80
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id                = azurerm_lb.vmss_lb.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = "vmss1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  sku                 = "Standard_B1s" 
  instances           = 2
  admin_password      = var.admin_password
  admin_username      = "localadmin"
  
  zones               = ["1", "2", "3"]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vmss_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      
    }
  }
  
  boot_diagnostics {
    storage_account_uri = null
  }
}
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss.id

  profile {
    name = "defaultProfile"

    capacity {  
      default = "2"
      minimum = "2"  
      maximum = "10" 
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M" 
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "PercentChangeCount"
        value     = "50" 
        cooldown  = "PT5M" 
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "PercentChangeCount"
        value     = "50" 
        cooldown  = "PT5M"
      }
    }
  }
}