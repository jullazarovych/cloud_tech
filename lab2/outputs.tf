output "management_group_id" {
  value = azurerm_management_group.mg.id
}

output "management_group_name" {
  value = azurerm_management_group.mg.display_name
}

output "helpdesk_group_id" {
  value = azuread_group.helpdesk.id
}

output "vm_contributor_role_id" {
  value = data.azurerm_role_definition.vm_contributor.id
}

output "custom_role_id" {
  value = azurerm_role_definition.custom_support_request.id
}

output "vm_contributor_assignment_id" {
  value = azurerm_role_assignment.helpdesk_vm_contributor.id
}

output "custom_role_assignment_id" {
  value = azurerm_role_assignment.helpdesk_custom_role.id
}