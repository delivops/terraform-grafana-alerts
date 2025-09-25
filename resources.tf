resource "grafana_rule_group" "alerts" {
  count            = length(var.alerts) > 0 ? 1 : 0
  name             = var.rule_group_name
  folder_uid       = var.folder_uid
  interval_seconds = 60

  dynamic "rule" {
    for_each = var.alerts
    content {
      name           = rule.value.name
      condition      = "A"
      for            = "5m"
      no_data_state  = "OK"
      exec_err_state = "OK"

      data {
        ref_id = "A"
        relative_time_range {
          from = 600
          to   = 0
        }
        datasource_uid = data.grafana_data_source.prometheus.uid
        model = jsonencode({
          datasource = {
            type = "prometheus"
            uid  = data.grafana_data_source.prometheus.uid
          }
          editorMode    = "code"
          expr          = rule.value.expr
          instant       = true
          intervalMs    = 1000
          legendFormat  = "__auto"
          maxDataPoints = 43200
          range         = false
          refId         = "A"
        })
      }
      
      # Opinionated production-ready annotations
      annotations = {
        description = rule.value.description != null ? rule.value.description : "Alert: ${rule.value.name}"
        summary     = "${rule.value.name}"
        runbook_url = rule.value.runbook_url != null ? rule.value.runbook_url : "${var.grafana_url}/alerting/list"
      }
      
      # Opinionated production-ready labels
      labels = {
        severity   = rule.value.severity
        priority   = local.severity_map[rule.value.severity]
        alert_name = rule.value.name
        cluster    = var.cluster_name
        team       = rule.value.team != null ? rule.value.team : "platform"
        component  = rule.value.component != null ? rule.value.component : "system"
      }
      
      notification_settings {
        contact_point   = var.contact_point_name
        group_by        = var.notification_settings.group_by
        group_wait      = var.notification_settings.group_wait
        group_interval  = var.notification_settings.group_interval
        repeat_interval = var.notification_settings.repeat_interval
      }
    }
  }
}


