output "web_app_1_url" {
  value = "https://${azurerm_windows_web_app.web1.default_hostname}"
}

output "web_app_2_url" {
  value = "https://${azurerm_windows_web_app.web2.default_hostname}"
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "application_insights_connection_string" {
  value     = azurerm_application_insights.appinsights.connection_string
  sensitive = true
}

output "action_group_id" {
  value = azurerm_monitor_action_group.sre_agent.id
}
