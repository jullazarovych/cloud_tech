resource "azurerm_resource_group" "rg" {
  name     = "az104-rg9b"
  location = "Brazil South"
}

resource "azurerm_container_group" "aci" {
  name                = "az104-c1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"
  
  dns_name_label      = "juliala125-lab9b-container" 

  container {
    name   = "aci-helloworld"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest" 
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    environment = "lab-09b"
  }
}

