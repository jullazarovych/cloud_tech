terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
    
  required_version = ">= 1.4.0"
}

provider "azurerm" {
  features {}
  subscription_id = "509d0f95-81ba-4aad-b477-d193f2c659f8"
  tenant_id       = "2752402b-4a24-4bbb-b112-36a0da5a9cdc"  
}


provider "azuread" {}