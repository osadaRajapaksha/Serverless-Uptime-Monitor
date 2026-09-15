variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-uptime-monitor-prod"
}

variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "project_prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "uptimemon"
}

variable "target_endpoints" {
  description = "Comma-separated list of endpoints to monitor"
  type        = string
  default     = "https://www.google.com,https://www.microsoft.com"
}

variable "alert_email_address" {
  description = "Email address to send alerts to"
  type        = string
  default     = "admin@example.com"
}
