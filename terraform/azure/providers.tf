terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # CI state account (personal-technology docs/418): a separate account from the
  # admin-only bootstrap state, in the management subscription.
  #
  # No resource_group_name / subscription_id on purpose. With use_azuread_auth
  # and the default lookup_blob_endpoint = false, the backend infers the blob URL
  # from the account name and talks ONLY to the data plane, so CI needs just the
  # container-scoped Storage Blob Data role and no management-plane role in the
  # management subscription. Plan: Blob Data Reader (-lock=false). Apply: Blob
  # Data Contributor (takes the lease lock).
  backend "azurerm" {
    storage_account_name = "stazutfciprodcus001"
    container_name       = "tfstate"
    key                  = "azure-workloads/terraform.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
  }
}

# subscription_id comes from ARM_SUBSCRIPTION_ID (a workload subscription in the
# landingzones or sandbox MG, the only scopes where CI holds roles).
provider "azurerm" {
  features {}
  use_oidc            = true
  storage_use_azuread = true

  # azurerm otherwise registers resource providers on startup, which needs
  # write access at subscription scope. The Reader-only plan identity can't, so
  # every PR plan would fail. Register what workloads need explicitly instead.
  resource_provider_registrations = "none"
}
