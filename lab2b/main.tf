resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg2"
  location = "Poland Central"

  tags = {
    "Cost Center" = "000"
  }
}

data "azurerm_policy_definition" "require_tag_value" {
  display_name = "Require a tag and its value on resources"
}

resource "azurerm_resource_group_policy_assignment" "require_cost_center_tag" {
  name                 = "require-cost-center-tag"
  display_name         = "Require Cost Center tag and its value on resources"
  description          = "Require Cost Center tag and its value on all resources in the resource group"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.require_tag_value.id
  enforce             = true

  parameters = jsonencode({
    tagName  = { value = "Cost Center" }
    tagValue = { value = "000" }
  })
}