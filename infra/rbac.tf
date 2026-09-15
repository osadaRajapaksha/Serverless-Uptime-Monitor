# Assign Storage Table Data Contributor to the Function App's Managed Identity
# This follows the principle of least privilege.
resource "azurerm_role_assignment" "table_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id
}
