# Action Group for sending emails
resource "azurerm_monitor_action_group" "email_ag" {
  name                = "${var.project_prefix}-email-ag"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "UptimeAlert"

  email_receiver {
    name                    = "admin-email"
    email_address           = var.alert_email_address
    use_common_alert_schema = true
  }
}

# Log Alert for non-200 responses
resource "azurerm_monitor_scheduled_query_rules_alert" "non_200_alert" {
  name                = "${var.project_prefix}-non200-alert"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  data_source_id = azurerm_application_insights.app_insights.id
  description    = "Alert when endpoint returns non-200 status code"
  enabled        = true

  query = <<-QUERY
    traces
    | where message contains "returned non-200 status code"
  QUERY

  severity    = 1
  frequency   = 15
  time_window = 15

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group           = [azurerm_monitor_action_group.email_ag.id]
    email_subject          = "Endpoint Uptime Alert"
  }
}
