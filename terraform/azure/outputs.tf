output "workloads_resource_group_name" {
  description = "Name of the workloads resource group"
  value       = azurerm_resource_group.workloads.name
}
