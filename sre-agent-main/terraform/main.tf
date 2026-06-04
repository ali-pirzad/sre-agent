terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  azuread_administrator {
    login_username = "sre-agent-sql-admins"
    object_id      = "596c0966-817b-463d-ab64-26a0ca7e83fb"
  }
}

# SQL Database
resource "azurerm_mssql_database" "db" {
  name      = var.sql_database_name
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
}

# Allow Azure services to access SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = "sre-agent-kv-2026"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Access policy for the deployer (Terraform)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

# Store SQL connection string in Key Vault
resource "azurerm_key_vault_secret" "sql_connection" {
  name         = "SqlConnectionString"
  value        = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.kv.id
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "sre-agent-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "B1"
}

# Web App 1
resource "azurerm_windows_web_app" "web1" {
  name                = "sre-agent-web1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      dotnet_version = "v8.0"
    }
    health_check_path = "/"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_connection.versionless_id})"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                       = "Production"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"         = azurerm_application_insights.appinsights.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION"    = "~3"
  }
}

# Key Vault access policy for Web App 1
resource "azurerm_key_vault_access_policy" "web1" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_web_app.web1.identity[0].principal_id

  secret_permissions = ["Get"]
}

# Web App 2
resource "azurerm_windows_web_app" "web2" {
  name                = "sre-agent-web2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      dotnet_version = "v8.0"
    }
    health_check_path = "/"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_connection.versionless_id})"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                       = "Production"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"         = azurerm_application_insights.appinsights.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION"    = "~3"
  }
}

# Key Vault access policy for Web App 2
resource "azurerm_key_vault_access_policy" "web2" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_web_app.web2.identity[0].principal_id

  secret_permissions = ["Get"]
}

# ============================================================
# MONITORING & ALERTING
# ============================================================

# Log Analytics Workspace (required for Application Insights)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "sre-agent-law"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                = "sre-agent-appinsights"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

# Action Group - will be connected to SRE Agent via Incident Platform
resource "azurerm_monitor_action_group" "sre_agent" {
  name                = "sre-agent-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "SREAgent"
  enabled             = true

  email_receiver {
    name          = "admin-email"
    email_address = "alipirzad@microsoft.com"
  }
}

# Alert: HTTP Server Errors (5xx) on Web App 1
resource "azurerm_monitor_metric_alert" "web1_http_5xx" {
  name                = "web1-http-5xx-errors"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web1.id]
  description         = "Alert when web1 returns HTTP 5xx errors"
  severity            = 1
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 3
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

# Alert: HTTP Server Errors (5xx) on Web App 2
resource "azurerm_monitor_metric_alert" "web2_http_5xx" {
  name                = "web2-http-5xx-errors"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web2.id]
  description         = "Alert when web2 returns HTTP 5xx errors"
  severity            = 1
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 3
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

# Alert: Web App 1 Health Check Failures (app stopped/unresponsive)
resource "azurerm_monitor_metric_alert" "web1_health" {
  name                = "web1-health-check-failed"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web1.id]
  description         = "Alert when web1 health check fails (app down)"
  severity            = 0
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HealthCheckStatus"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

# Alert: Web App 2 Health Check Failures
resource "azurerm_monitor_metric_alert" "web2_health" {
  name                = "web2-health-check-failed"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web2.id]
  description         = "Alert when web2 health check fails (app down)"
  severity            = 0
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HealthCheckStatus"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

# Alert: High Response Time on Web App 1
resource "azurerm_monitor_metric_alert" "web1_response_time" {
  name                = "web1-high-response-time"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web1.id]
  description         = "Alert when web1 average response time exceeds 5 seconds"
  severity            = 2
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

# Alert: High Response Time on Web App 2
resource "azurerm_monitor_metric_alert" "web2_response_time" {
  name                = "web2-high-response-time"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web2.id]
  description         = "Alert when web2 average response time exceeds 5 seconds"
  severity            = 2
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

# Alert: SQL Database Connection Failures (via App Insights)
resource "azurerm_monitor_metric_alert" "sql_connection_failures" {
  name                = "sql-dependency-failures"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_application_insights.appinsights.id]
  description         = "Alert when SQL dependency calls fail"
  severity            = 1
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Insights/components"
    metric_name      = "dependencies/failed"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 5

    dimension {
      name     = "dependency/type"
      operator = "Include"
      values   = ["SQL"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

# Alert: App Unavailable (responds with server errors indicating crash/unavailable)
resource "azurerm_monitor_metric_alert" "web1_503" {
  name                = "web1-service-unavailable"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web1.id]
  description         = "Alert when web1 stops responding (0 requests = app down)"
  severity            = 0
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}

resource "azurerm_monitor_metric_alert" "web2_503" {
  name                = "web2-service-unavailable"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_windows_web_app.web2.id]
  description         = "Alert when web2 stops responding (0 requests = app down)"
  severity            = 0
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.sre_agent.id
  }
}
