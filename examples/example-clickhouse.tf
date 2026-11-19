# Example: ClickHouse SQL Alerts Setup
module "clickhouse_alerts" {
  source = "../"

  rule_group_name = "ClickHouse Alerts"

  folder_uid = "grafana-folder-uid"

  # Use the ClickHouse datasource (grafana-clickhouse-datasource plugin)
  datasource_uid  = "clickhouse"
  datasource_type = "grafana-clickhouse-datasource"

  clickhouse_alerts = [
    {
      # One row, one numeric column: a single value
      name        = "No Paid Orders"
      query       = "SELECT count() AS paid_orders FROM orders WHERE status = 'paid' AND $__timeFilter(created_at)"
      time_range  = 3600
      operator    = "<"
      threshold   = 1
      severity    = "critical"
      description = "No paid orders in the last hour"
      team        = "payments"
    },
    {
      # String columns become labels: one series (and one alert instance) per country
      name          = "Failed Payments By Country"
      query         = "SELECT country, countIf(status = 'failed') / count() * 100 AS failed_pct FROM payments WHERE $__timeFilter(created_at) GROUP BY country HAVING count() >= 20"
      time_range    = 1800
      operator      = ">"
      threshold     = 20
      severity      = "error"
      description   = "More than 20% of payments failed in {{ $labels.country }} in the last 30 minutes"
      slack_labels  = ["country"] # Show which country
      no_data_state = "OK"        # No country with 20+ payments returns no rows
    },
    {
      # time_series format: needs a time column, the reducer picks one value per series
      name        = "Insert Errors Spike"
      format      = "time_series"
      query       = "SELECT toStartOfMinute(event_time) AS time, count() AS errors FROM system.query_log WHERE type = 'ExceptionBeforeStart' AND query_kind = 'Insert' AND $__timeFilter(event_time) GROUP BY time ORDER BY time"
      time_range  = 900
      reducer     = "max"
      operator    = ">"
      threshold   = 10
      severity    = "warning"
      description = "More than 10 failed inserts in one minute"
    }
  ]
}
