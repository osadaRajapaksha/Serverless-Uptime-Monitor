resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account (Used by both Function App and Table Storage)
resource "azurerm_storage_account" "sa" {
  name                     = "${var.project_prefix}storageacc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Table Storage for Results
resource "azurerm_storage_table" "table" {
  name                 = "UptimeMonitorResults"
  storage_account_name = azurerm_storage_account.sa.name
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.project_prefix}-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# App Service Plan (Consumption)
resource "azurerm_service_plan" "asp" {
  name                = "${var.project_prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Linux Function App
resource "azurerm_linux_function_app" "func" {
  name                       = "${var.project_prefix}-funcapp"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
    application_insights_key = azurerm_application_insights.app_insights.instrumentation_key
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "TARGET_ENDPOINTS"         = var.target_endpoints
    "TABLE_NAME"               = azurerm_storage_table.table.name
  }

  identity {
    type = "SystemAssigned"
  }
}
