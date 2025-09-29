resource "grafana_folder" "folder" {
  count = var.folder_uid == null ? 1 : 0
  title = var.rule_group_name
}

# Create a notification policy to route alerts to the contact point
resource "grafana_notification_policy" "default" {
  count         = var.contact_point_name == null ? 1 : 0
  group_by      = var.notification_settings.group_by
  contact_point = grafana_contact_point.slack[0].name

  group_wait      = var.notification_settings.group_wait
  group_interval  = var.notification_settings.group_interval
  repeat_interval = var.notification_settings.repeat_interval
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
*Current Value:* {{ if .Values }} {{ range .Values }}{{ . }}{{ end }} {{ else }} No data {{ end }}
*Severity:* {{ .Annotations.severity | toUpper }}
*Started at:* {{ .StartsAt.Day }}-{{ .StartsAt.Month }}-{{ .StartsAt.Year }} {{ .StartsAt.Hour   }}:{{ .StartsAt.Minute   }}:{{ .StartsAt.Second   }}

*<{{ .SilenceURL }}|Silence This Alert>*{{ if .Annotations.runbook_url }} | *<{{ .Annotations.runbook_url }}|View Runbook>*{{ end }}
{{ end }}
EOT
  }
}


resource "grafana_rule_group" "alerts" {
  count            = length(var.alerts) > 0 ? 1 : 0
  name             = var.rule_group_name
  folder_uid       = var.folder_uid != null ? var.folder_uid : grafana_folder.folder[0].uid
  interval_seconds = 60

  dynamic "rule" {
    for_each = var.alerts
    content {
      name           = rule.value.name
      condition      = "B"
      for            = rule.value.pending_for
      no_data_state  = rule.value.no_data_state
      exec_err_state = rule.value.exec_err_state

      # Query A: The metric calculation
      data {
        ref_id = "A"
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = local.datasource_uid
        model = jsonencode({
          datasource = {
            type = var.datasource_type
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

      # Query B: The threshold comparison
      data {
        ref_id = "B"
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = "__expr__"
        model = jsonencode({
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
              operator = {
                type = "and"
              }
              query = {
                params = ["A"]
              }
              reducer = {
                params = []
                type   = "last"
              }
              type = "query"
            }
          ]
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression    = ""
          hide          = false
          intervalMs    = 1000
          maxDataPoints = 43200
          refId         = "B"
          type          = "classic_conditions"
        })
      }

      # Opinionated production-ready annotations
      annotations = {
        description = rule.value.description != null ? rule.value.description : "Alert: ${rule.value.name}"
        runbook_url = rule.value.runbook_url != null ? rule.value.runbook_url : null
        severity    = rule.value.severity
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
