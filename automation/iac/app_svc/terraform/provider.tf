terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

# Data source for existing ACR
data "azurerm_container_registry" "existing_acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}