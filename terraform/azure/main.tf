# ==============================================================================
# Azure Cloud Infrastructure Workloads
# Deployed automatically via GitHub Actions (infra-cloud-deployments)
# ==============================================================================

# Resource Group for Cloud Workloads & Services
resource "azurerm_resource_group" "workloads" {
  name     = "rg-azure-workloads-${var.env}-cus-001"
  location = var.location

  tags = {
    Environment = var.env
    ManagedBy   = "github-actions"
    Repository  = "infra-cloud-deployments"
  }
}
