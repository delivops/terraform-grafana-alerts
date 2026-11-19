# Plan-only tests for clickhouse_alerts. The grafana provider is mocked, so no Grafana is needed:
#   terraform init && terraform test

mock_provider "grafana" {}

variables {
  rule_group_name    = "ClickHouse Test"
  folder_uid         = "folder"
  contact_point_name = "contact-point"
  datasource_uid     = "clickhouse-uid"
  datasource_type    = "grafana-clickhouse-datasource"
}

run "table_query_defaults" {
  command = plan

  variables {
    clickhouse_alerts = [
      {
        name      = "orders by country"
        query     = "SELECT country, count() AS orders FROM orders WHERE $__timeFilter(created_at) GROUP BY country"
        threshold = 10
        severity  = "warning"
      }
    ]
  }

  assert {
    condition     = length(grafana_rule_group.alerts) == 1 && length(grafana_rule_group.alerts[0].rule) == 1
    error_message = "one rule group with one rule expected"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[0].model).rawSql == "SELECT country, count() AS orders FROM orders WHERE $__timeFilter(created_at) GROUP BY country"
    error_message = "query must be sent as rawSql unchanged"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[0].model).format == 1 && jsondecode(grafana_rule_group.alerts[0].rule[0].data[0].model).queryType == "table"
    error_message = "default format must be table (format 1, queryType table)"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[0].model).editorType == "sql"
    error_message = "editorType must be sql"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].data[0].query_type == "table"
    error_message = "data.query_type must match the model's queryType, or every plan shows a diff"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[0].model).datasource == { type = "grafana-clickhouse-datasource", uid = "clickhouse-uid" }
    error_message = "model datasource must be the clickhouse datasource"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].data[0].datasource_uid == "clickhouse-uid"
    error_message = "query A must use the datasource uid"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].data[0].relative_time_range[0].from == 600 && grafana_rule_group.alerts[0].rule[0].data[0].relative_time_range[0].to == 0
    error_message = "default time range must be the last 600 seconds"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[1].model).reducer == "last"
    error_message = "default reducer must be last"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[2].model).conditions[0].evaluator == { params = [10], type = "gt" }
    error_message = "default threshold evaluator must be gt 10"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].no_data_state == "OK" && grafana_rule_group.alerts[0].rule[0].exec_err_state == "Alerting"
    error_message = "defaults: no_data_state OK, exec_err_state Alerting"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].condition == "C" && grafana_rule_group.alerts[0].rule[0].for == "5m"
    error_message = "condition must be C, pending for 5m"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].labels["priority"] == "P3"
    error_message = "warning must map to priority P3"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].notification_settings[0].contact_point == "contact-point"
    error_message = "rules must use the given contact point"
  }

  assert {
    condition     = output.clickhouse_alert_count == 1 && output.alert_count == 1 && output.configured_alerts == ["orders by country"]
    error_message = "outputs must count clickhouse alerts"
  }
}

run "time_series_and_overrides" {
  command = plan

  variables {
    clickhouse_alerts = [
      {
        name           = "errors per minute"
        format         = "time_series"
        query          = "SELECT toStartOfMinute(t) AS time, count() AS errors FROM logs WHERE $__timeFilter(t) GROUP BY time ORDER BY time"
        time_range     = 3600
        reducer        = "median"
        operator       = "<="
        threshold      = 2.5
        severity       = "critical"
        description    = "custom description"
        slack_labels   = ["country", "psp"]
        pending_for    = "0s"
        no_data_state  = "Alerting"
        exec_err_state = "KeepLast"
      }
    ]
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[0].model).format == 0 && jsondecode(grafana_rule_group.alerts[0].rule[0].data[0].model).queryType == "timeseries"
    error_message = "time_series must be format 0, queryType timeseries"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].data[0].query_type == "timeseries"
    error_message = "data.query_type must match the model's queryType"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].data[0].relative_time_range[0].from == 3600
    error_message = "time_range must set the query time range"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[1].model).reducer == "median"
    error_message = "reducer must be passed to query B"
  }

  assert {
    condition     = jsondecode(grafana_rule_group.alerts[0].rule[0].data[2].model).conditions[0].evaluator == { params = [2.5], type = "lte" }
    error_message = "operator <= must map to lte"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].no_data_state == "Alerting" && grafana_rule_group.alerts[0].rule[0].exec_err_state == "KeepLast" && grafana_rule_group.alerts[0].rule[0].for == "0s"
    error_message = "per-alert state overrides must be used"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].annotations["description"] == "custom description" && grafana_rule_group.alerts[0].rule[0].annotations["slack_labels"] == "country|psp"
    error_message = "description and slack_labels annotations must be set"
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].labels["priority"] == "P1"
    error_message = "critical must map to priority P1"
  }
}

run "mixed_with_other_alert_types" {
  command = plan

  variables {
    prometheus_alerts = [
      { name = "prom", metric_expr = "up", threshold = 1, severity = "info" }
    ]
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "info" }
    ]
  }

  assert {
    condition     = length(grafana_rule_group.alerts[0].rule) == 2
    error_message = "both alert types must be rules in the same group"
  }

  assert {
    condition     = output.configured_alerts == ["prom", "ch"] && output.clickhouse_alert_count == 1 && output.alert_count == 2
    error_message = "outputs must include both alert types"
  }
}

run "no_alerts_no_rule_group" {
  command = plan

  assert {
    condition     = length(grafana_rule_group.alerts) == 0 && output.clickhouse_alert_count == 0
    error_message = "no rule group without alerts"
  }
}

run "wrong_datasource_type" {
  command = plan

  variables {
    datasource_type = "prometheus"
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "info" }
    ]
  }

  expect_failures = [grafana_rule_group.alerts]
}

run "invalid_format" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", format = "logs", threshold = 0, severity = "info" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "invalid_operator" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", operator = "=>", threshold = 0, severity = "info" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "invalid_reducer" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", format = "time_series", reducer = "stddev", threshold = 0, severity = "info" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "time_range_too_small" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", time_range = 59, threshold = 0, severity = "info" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "time_range_too_large" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", time_range = 86401, threshold = 0, severity = "info" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "reducer_not_implemented_by_grafana" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "info", format = "time_series", reducer = "diff" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "reducer_on_table_format" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "info", reducer = "sum" } # table format compares each row, reduce would be a no-op
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "invalid_severity" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "high" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "invalid_no_data_state" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "info", no_data_state = "Ok" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "no_data_state_error_not_allowed" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "info", no_data_state = "Error" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "invalid_exec_err_state" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", threshold = 0, severity = "info", exec_err_state = "NoData" }
    ]
  }

  expect_failures = [var.clickhouse_alerts]
}

run "time_range_max_allowed" {
  command = plan

  variables {
    clickhouse_alerts = [
      { name = "ch", query = "SELECT 1 AS v", time_range = 86400, threshold = 0, severity = "info", no_data_state = "KeepLast", exec_err_state = "Error" }
    ]
  }

  assert {
    condition     = grafana_rule_group.alerts[0].rule[0].data[0].relative_time_range[0].from == 86400
    error_message = "86400 must be allowed"
  }
}
