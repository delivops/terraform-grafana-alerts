variable "rule_group_name" {
  description = "Name of the rule group"
  type        = string
}
variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "folder_uid" {
  description = "Uid of the Grafana folder"
  type        = string
}
variable "contact_point_name" {
  description = "Name of the contact point"
  type        = string

}
variable "alerts" {
  description = "List of alert configurations"
  type = list(
    object({
      name        = string
      expr        = string
      severity    = string
      description = optional(string, null)
      runbook_url = optional(string, null)
      team        = optional(string, null)
      component   = optional(string, null)
    })
  )
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
    group_wait      = optional(string, "45s")
    group_interval  = optional(string, "6m")
    repeat_interval = optional(string, "12h")
  })
  default = {
    group_by        = ["alertname", "cluster", "severity"]
    group_wait      = "45s"
    group_interval  = "6m"
    repeat_interval = "12h"
  }
}
