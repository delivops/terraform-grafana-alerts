terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }
}

data "grafana_data_source" "datasource" {
  count = var.datasource_uid == null ? 1 : 0
  name  = var.datasource_name
}

locals {
  # Use provided UID or lookup by name
  datasource_uid = var.datasource_uid != null ? var.datasource_uid : data.grafana_data_source.datasource[0].uid

  # Alert operator to Grafana threshold evaluator type
  operator_map = {
    ">"  = "gt"
    "<"  = "lt"
    ">=" = "gte"
    "<=" = "lte"
    "==" = "eq"
    "!=" = "neq"
  }

  # Total number of alerts, the rule group is only created when there is at least one
  alert_count = length(var.prometheus_alerts) + length(var.cloudwatch_alerts) + length(var.cloudwatch_logs_alerts) + length(var.elasticsearch_alerts) + length(var.clickhouse_alerts)

  # ClickHouse plugin query format: the plugin's Format enum and the matching queryType
  clickhouse_formats = {
    "time_series" = { format = 0, query_type = "timeseries" }
    "table"       = { format = 1, query_type = "table" }
  }

  severity_map = {
    "critical" = "P1"
    "error"    = "P2"
    "warning"  = "P3"
    "info"     = "P4"
  }
}
