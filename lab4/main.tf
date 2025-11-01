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