terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-azure-tfstate-prod-cus-001"
    storage_account_name = "stazutfstateprodcus001"
    container_name       = "tfstate"
    key                  = "azure-workloads/terraform.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc            = true
  storage_use_azuread = true
}
