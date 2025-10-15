resource "azurerm_management_group" "mg" {
  name         = var.management_group_id
  display_name = var.management_group_name
}

data "azurerm_management_group" "mg_data" {
  name = azurerm_management_group.mg.name
}

data "azurerm_subscription" "current" {}

resource "azurerm_management_group_subscription_association" "mg_sub" {
  management_group_id = azurerm_management_group.mg.id
  subscription_id     = data.azurerm_subscription.current.id
}

resource "azuread_group" "helpdesk" {
  display_name     = var.helpdesk_group_name
  security_enabled = true
  description      = "Support staff responsible for handling VM-related issues"
}

data "azurerm_role_definition" "vm_contributor" {
  name  = "Virtual Machine Contributor"
  scope = data.azurerm_management_group.mg_data.id
}

resource "azurerm_role_assignment" "helpdesk_vm_contributor" {
  scope              = data.azurerm_management_group.mg_data.id
  role_definition_id = data.azurerm_role_definition.vm_contributor.id
  principal_id       = azuread_group.helpdesk.id
}

resource "azurerm_role_definition" "custom_support_request" {
  name        = var.custom_role_name
  scope       = data.azurerm_management_group.mg_data.id
  description = "A custom contributor role for support requests."

  permissions {
    actions = [
      "Microsoft.Authorization/*/read",
      "Microsoft.Support/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/read"
    ]
    not_actions = [
      "Microsoft.Support/register/action"
    ]
  }

  assignable_scopes = [
    data.azurerm_management_group.mg_data.id
  ]
}

resource "azurerm_role_assignment" "helpdesk_custom_role" {
  scope              = data.azurerm_management_group.mg_data.id
  role_definition_id = azurerm_role_definition.custom_support_request.role_definition_resource_id
  principal_id       = azuread_group.helpdesk.id
}