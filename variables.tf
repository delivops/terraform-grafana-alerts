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

variable "prometheus_alerts" {
  description = "List of Prometheus alert configurations"
  type = list(
    object({
      name           = string
      metric_expr    = string                # Prometheus query expression
      operator       = optional(string, ">") # >, <, ==, !=, >=, <=
      threshold      = number                # Threshold value
      severity       = string
      description    = optional(string, null)
      runbook_url    = optional(string, null)
      team           = optional(string, null)
      component      = optional(string, null)
      slack_labels   = optional(list(string), []) # Prometheus labels to show in Slack (e.g., ["instance", "job", "service"])
      pending_for    = optional(string, "5m")
      no_data_state  = optional(string, "Alerting")
      exec_err_state = optional(string, "Alerting")
    })
  )
  default = []

  validation {
    condition = alltrue([
      for alert in var.prometheus_alerts : contains([">", "<", "==", "!=", ">=", "<="], alert.operator)
    ])
    error_message = "operator must be one of: >, <, ==, !=, >=, <="
  }
}

variable "cloudwatch_alerts" {
  description = "List of CloudWatch alert configurations"
  type = list(
    object({
      name           = string
      namespace      = string                # AWS namespace (e.g., AWS/EC2)
      metric_name    = string                # CloudWatch metric name
      dimensions     = optional(map(string), {}) # CloudWatch dimensions
      statistic      = optional(string, "Average") # CloudWatch statistic (Sum, Average, Maximum, etc.)
      period         = optional(string, "300") # CloudWatch period in seconds
      region         = optional(string, "default") # CloudWatch region
      reducer        = optional(string, "last") # Reducer function (last, mean, max, min, sum, count, etc.)
      operator       = optional(string, ">") # >, <, ==, !=, >=, <=
      threshold      = number                # Threshold value
      severity       = string
      description    = optional(string, null)
      runbook_url    = optional(string, null)
      team           = optional(string, null)
      component      = optional(string, null)
      slack_labels   = optional(list(string), []) # CloudWatch dimensions to show in Slack (e.g., ["InstanceId", "AutoScalingGroupName"])
      pending_for    = optional(string, "5m")
      no_data_state  = optional(string, "Alerting")
      exec_err_state = optional(string, "Alerting")
    })
  )
  default = []

  validation {
    condition = alltrue([
      for alert in var.cloudwatch_alerts : contains([">", "<", "==", "!=", ">=", "<="], alert.operator)
    ])
    error_message = "operator must be one of: >, <, ==, !=, >=, <="
  }

  validation {
    condition = alltrue([
      for alert in var.cloudwatch_alerts : contains(["last", "mean", "max", "min", "sum", "count", "diff", "diff_abs", "count_non_null"], alert.reducer)
    ])
    error_message = "reducer must be one of: last, mean, max, min, sum, count, diff, diff_abs, count_non_null"
  }
}

variable "elasticsearch_alerts" {
  description = "List of Elasticsearch alert configurations"
  type = list(
    object({
      name           = string
      index          = string                # Elasticsearch index
      query          = string                # Elasticsearch query
      operator       = optional(string, ">") # >, <, ==, !=, >=, <=
      threshold      = number                # Threshold value
      severity       = string
      description    = optional(string, null)
      runbook_url    = optional(string, null)
      team           = optional(string, null)
      component      = optional(string, null)
      slack_labels   = optional(list(string), []) # Elasticsearch labels to show in Slack (e.g., ["index", "type", "id"])
      pending_for    = optional(string, "5m")
      no_data_state  = optional(string, "Alerting")
      exec_err_state = optional(string, "Alerting")
      aggregation = object({
        field         = string
        id            = string
        min_doc_count = string
        order         = string
        orderBy       = string
        size          = string
        missing       = string
        type          = string
        interval      = optional(string, "auto")
      })
      metric = object({
        field               = string
        id                  = string
        precision_threshold = optional(string, null)
        type                = optional(string, null)
      })
    })
  )
  default = []

  validation {
    condition = alltrue([
      for alert in var.elasticsearch_alerts : contains([">", "<", "==", "!=", ">=", "<="], alert.operator)
    ])
    error_message = "operator must be one of: >, <, ==, !=, >=, <="
  }
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
