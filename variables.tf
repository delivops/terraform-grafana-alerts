variable "rule_group_name" {
  description = "Name of the rule group"
  type        = string
}

variable "folder_uid" {
  description = "Uid of the Grafana folder to place the rule group in. If null, a new folder named after the rule_group_name will be created."
  type        = string
  default     = null
}

variable "slack_api_token" {
  description = "Slack Bot User OAuth Token (xoxb-...). Get from https://api.slack.com/apps"
  type        = string
  default     = null # Optional for testing
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel to send alerts to (with # prefix, e.g., #alerts)"
  type        = string
  default     = "#alerts"
}

variable "contact_point_name" {
  description = "Name of the contact point to use for notifications. Required if not creating a new Slack contact point."
  type        = string
  default     = null

  validation {
    condition     = var.slack_api_token != null || var.contact_point_name != null
    error_message = "Either slack_api_token must be provided to create a new Slack contact point, or contact_point_name must be provided to use an existing contact point."
  }
}

variable "alerts" {
  description = "List of alert configurations"
  type = list(
    object({
      name           = string
      metric_expr    = string                # Just the metric calculation part
      operator       = optional(string, ">") # >, <, ==, !=, >=, <=
      threshold      = number                # Threshold value
      severity       = string
      description    = optional(string, null)
      runbook_url    = optional(string, null)
      team           = optional(string, null)
      component      = optional(string, null)
      pending_for    = optional(string, "5m")
      no_data_state  = optional(string, "Alerting")
      exec_err_state = optional(string, "Alerting")
    })
  )

  validation {
    condition = alltrue([
      for alert in var.alerts : contains([">", "<", "==", "!=", ">=", "<="], alert.operator)
    ])
    error_message = "operator must be one of: >, <, ==, !=, >=, <="
  }
}

variable "grafana_url" {
  description = "Base URL for Grafana instance"
  type        = string
  default     = "https://grafana.company.com"
}

variable "grafana_api_key" {
  description = "Grafana API key with permissions to manage alerting"
  type        = string
  sensitive   = true
}

# Optional: Override default notification settings
variable "notification_settings" {
  description = "Notification settings for alerts"
  type = object({
    group_by        = optional(list(string), ["alertname", "cluster", "severity"])
    group_wait      = optional(string, "30s")
    group_interval  = optional(string, "5m")
    repeat_interval = optional(string, "4h")
  })
  default = {
    group_by        = ["alertname", "cluster", "severity"]
    group_wait      = "30s"
    group_interval  = "5m"
    repeat_interval = "4h"
  }
}

# Datasource configuration
variable "datasource_name" {
  description = "Name of the Grafana datasource to use for alerts"
  type        = string
  default     = null
}

variable "datasource_uid" {
  description = "UID of the Grafana datasource to use for alerts (takes precedence over datasource_name)"
  type        = string
  default     = null
}

variable "datasource_type" {
  description = "Type of the datasource (e.g., prometheus, loki, influxdb, etc.)"
  type        = string
  default     = "prometheus"
}
