resource "grafana_folder" "folder" {
  count = var.folder_uid == null ? 1 : 0
  title = var.rule_group_name
}

# Create Slack contact point with inline templates
resource "grafana_contact_point" "slack" {
  count = var.contact_point_name == null ? 1 : 0
  name  = var.rule_group_name

  slack {
    token     = var.slack_api_token
    recipient = var.slack_channel
    title     = "[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}{{ if .CommonLabels.priority }} - {{ .CommonLabels.priority | toUpper }}{{ end }}"
    text      = <<-EOT
{{ range .Alerts }}
*Description:* {{ .Annotations.description }}
*Current Value:* {{ if .Values.B }}{{ printf "%.2f" .Values.B }}{{ else }}No data{{ end }}
*Severity:* {{ .Annotations.severity | toUpper }}
{{- if .Annotations.slack_labels }}
{{- $slack_labels := .Annotations.slack_labels }}
{{- $system_labels := "alertname|grafana_folder|__name__|priority|team|component" }}
{{- range .Labels.SortedPairs }}
{{- if and (match $slack_labels .Name) (not (match $system_labels .Name)) }}
*{{ .Name | title }}:* {{ .Value }}
{{- end }}
{{- end }}
{{- end }}
*Started at:* {{ .StartsAt | date "02-01-2006 15:04:05" }}

*<{{ .SilenceURL }}|Silence This Alert>*{{ if .Annotations.runbook_url }} | *<{{ .Annotations.runbook_url }}|View Runbook>*{{ end }}
{{ end }}
EOT
  }
}


resource "grafana_rule_group" "alerts" {
  count            = (length(var.prometheus_alerts) + length(var.cloudwatch_alerts)) > 0 ? 1 : 0
  name             = var.rule_group_name
  folder_uid       = var.folder_uid != null ? var.folder_uid : grafana_folder.folder[0].uid
  interval_seconds = 60

  # Prometheus alerts
  dynamic "rule" {
    for_each = var.prometheus_alerts
    content {
      name           = rule.value.name
      condition      = "C"
      for            = rule.value.pending_for
      no_data_state  = rule.value.no_data_state
      exec_err_state = rule.value.exec_err_state

      # Query A: Prometheus metric calculation
      data {
        ref_id = "A"
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = local.datasource_uid
        model = jsonencode({
          datasource = {
            type = "prometheus"
            uid  = local.datasource_uid
          }
          editorMode    = "code"
          expr          = rule.value.metric_expr
          instant       = true
          intervalMs    = 1000
          legendFormat  = "__auto"
          maxDataPoints = 43200
          range         = false
          refId         = "A"
        })
      }

      # Query B: Reduce - get single value per series (preserves labels)
      data {
        ref_id = "B"
        relative_time_range {
          from = 0
          to   = 0
        }
        datasource_uid = "__expr__"
        model = jsonencode({
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression = "A"
          reducer    = "last"
          settings = {
            mode             = "replaceNN"
            replaceWithValue = 0
          }
          refId = "B"
          type  = "reduce"
        })
      }

      # Query C: The threshold comparison
      data {
        ref_id = "C"
        relative_time_range {
          from = 0
          to   = 0
        }
        datasource_uid = "__expr__"
        model = jsonencode({
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression = "B"
          conditions = [
            {
              evaluator = {
                params = [rule.value.threshold]
                type = (rule.value.operator == ">" ? "gt" :
                  rule.value.operator == "<" ? "lt" :
                  rule.value.operator == ">=" ? "gte" :
                  rule.value.operator == "<=" ? "lte" :
                  rule.value.operator == "==" ? "eq" :
                rule.value.operator == "!=" ? "neq" : "gt")
              }
            }
          ]
          refId = "C"
          type  = "threshold"
        })
      }

      # Opinionated production-ready annotations
      annotations = {
        description = rule.value.description != null ? rule.value.description : "Alert: ${rule.value.name}"
        runbook_url = rule.value.runbook_url != null ? rule.value.runbook_url : null
        severity    = rule.value.severity
        slack_labels = join("|", rule.value.slack_labels)  # Convert list to pipe-separated string
      }

      labels = {
        priority  = local.severity_map[rule.value.severity]
        team      = rule.value.team != null ? rule.value.team : null
        component = rule.value.component != null ? rule.value.component : null
      }

      notification_settings {
        contact_point   = var.contact_point_name != null ? var.contact_point_name : grafana_contact_point.slack[0].name
        group_by        = var.notification_settings.group_by
        group_wait      = var.notification_settings.group_wait
        group_interval  = var.notification_settings.group_interval
        repeat_interval = var.notification_settings.repeat_interval
      }
    }
  }

  # CloudWatch alerts
  dynamic "rule" {
    for_each = var.cloudwatch_alerts
    content {
      name           = rule.value.name
      condition      = "C"
      for            = rule.value.pending_for
      no_data_state  = rule.value.no_data_state
      exec_err_state = rule.value.exec_err_state

      # Query A: CloudWatch metric calculation
      data {
        ref_id = "A"
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = local.datasource_uid
        model = jsonencode({
          datasource = {
            type = "cloudwatch"
            uid  = local.datasource_uid
          }
          namespace  = rule.value.namespace
          metricName = rule.value.metric_name
          dimensions = rule.value.dimensions
          statistic  = rule.value.statistic
          period     = rule.value.period
          region     = rule.value.region
          refId      = "A"
        })
      }

      # Query B: Reducer - reduce time series to single value
      data {
        ref_id = "B"
        relative_time_range {
          from = 0
          to   = 0
        }
        datasource_uid = "__expr__"
        model = jsonencode({
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression = "A"
          reducer    = rule.value.reducer
          refId = "B"
          type  = "reduce"
        })
      }

      # Query C: Threshold comparison - is above threshold
      data {
        ref_id = "C"
        relative_time_range {
          from = 0
          to   = 0
        }
        datasource_uid = "__expr__"
        model = jsonencode({
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression = "B"
          conditions = [
            {
              evaluator = {
                params = [rule.value.threshold]
                type = (rule.value.operator == ">" ? "gt" :
                  rule.value.operator == "<" ? "lt" :
                  rule.value.operator == ">=" ? "gte" :
                  rule.value.operator == "<=" ? "lte" :
                  rule.value.operator == "==" ? "eq" :
                rule.value.operator == "!=" ? "neq" : "gt")
              }
            }
          ]
          refId = "C"
          type  = "threshold"
        })
      }

      # Opinionated production-ready annotations
      annotations = {
        description = rule.value.description != null ? rule.value.description : "Alert: ${rule.value.name}"
        runbook_url = rule.value.runbook_url != null ? rule.value.runbook_url : null
        severity    = rule.value.severity
        slack_labels = join("|", rule.value.slack_labels)  # Convert list to pipe-separated regex pattern
      }

      labels = {
        priority  = local.severity_map[rule.value.severity]
        team      = rule.value.team != null ? rule.value.team : null
        component = rule.value.component != null ? rule.value.component : null
      }

      notification_settings {
        contact_point   = var.contact_point_name != null ? var.contact_point_name : grafana_contact_point.slack[0].name
        group_by        = var.notification_settings.group_by
        group_wait      = var.notification_settings.group_wait
        group_interval  = var.notification_settings.group_interval
        repeat_interval = var.notification_settings.repeat_interval
      }
    }
  }
}
