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
  subscription_id = "cce2f317-55ef-4a39-9db5-ca1cc8342d22"
  features {}
}

provider "azuread" {}