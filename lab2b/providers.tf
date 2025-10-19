terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.48.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "509d0f95-81ba-4aad-b477-d193f2c659f8"
}
