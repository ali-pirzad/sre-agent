variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "sre-agent-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralus"
}

variable "sql_server_name" {
  description = "Name of the SQL server"
  type        = string
  default     = "sre-agent-sqlserver"
}

variable "sql_database_name" {
  description = "Name of the SQL database"
  type        = string
  default     = "FlightBookingDb"
}

variable "sql_admin_username" {
  description = "SQL Server admin username"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server admin password"
  type        = string
  sensitive   = true
}
