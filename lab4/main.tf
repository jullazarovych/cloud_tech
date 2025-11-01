resource "azurerm_resource_group" "rg" {
  name     = "az104-rg4"
  location = "Poland Central" 
  }

resource "azurerm_virtual_network" "vnet" {
  name                = "CoreServicesVnet"
  location            = azurerm_resource_group.rg.location     
  resource_group_name = azurerm_resource_group.rg.name     
  address_space       = ["10.20.0.0/16"]                   
}

resource "azurerm_subnet" "shared" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name 
  address_prefixes     = ["10.20.10.0/24"]     
}

resource "azurerm_subnet" "db" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name 
  address_prefixes     = ["10.20.20.0/24"]                
}

resource "azurerm_virtual_network" "vnet_mfg" {
  name                = "ManufacturingVnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.30.0.0/16"] 
}

resource "azurerm_subnet" "sensor1" {
  name                 = "SensorSubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_mfg.name 
  address_prefixes     = ["10.30.20.0/24"] 
}

resource "azurerm_subnet" "sensor2" {
  name                 = "SensorSubnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_mfg.name
  address_prefixes     = ["10.30.21.0/24"] 
}

resource "azurerm_application_security_group" "asg_web" {
  name                = "asg-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg_secure" {
  name                = "myNSGSecure"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_asg_inbound" {
  name                        = "AllowASG"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"] 
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_secure.name

  source_application_security_group_ids = [azurerm_application_security_group.asg_web.id]
}

resource "azurerm_network_security_rule" "deny_internet_outbound" {
  name                        = "DenyInternetOutbound"
  priority                    = 4096 
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*" 
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  
  destination_address_prefix  = "Internet" 
  
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_secure.name
}
resource "azurerm_subnet_network_security_group_association" "shared_nsg_assoc" {
  subnet_id                 = azurerm_subnet.shared.id
  network_security_group_id = azurerm_network_security_group.nsg_secure.id
}