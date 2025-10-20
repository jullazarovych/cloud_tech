resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg2"
  location = "Poland Central"

  tags = {
    "Cost Center" = "000"
  }
}

data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}

resource "azurerm_resource_group_policy_assignment" "inherit_cost_center_tag" {
  name                 = "inherit-cost-center-tag-000"
  display_name         = "Inherit the Cost Center tag and its value 000 from the resource group if missing"
  description          = "Inherit the Cost Center tag and its value 000 from the resource group if missing"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id
  enforce             = true

  location = azurerm_resource_group.rg2.location
  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = { value = "Cost Center" }
  })
}

resource "azurerm_resource_policy_remediation" "remediate_tags" {
  name                 = "remediate-missing-cost-center-tag"
  resource_id          = azurerm_resource_group.rg2.id
  policy_assignment_id = azurerm_resource_group_policy_assignment.inherit_cost_center_tag.id
  depends_on = [azurerm_resource_group_policy_assignment.inherit_cost_center_tag]
}
resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg2.id
  lock_level = "CanNotDelete"
  notes      = "Prevents deletion of the resource group az104-rg2."
}