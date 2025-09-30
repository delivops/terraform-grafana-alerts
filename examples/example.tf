# Example 1: Testing with local Docker Compose setup
module "test_alerts" {
  source = "../"

  rule_group_name = "Docker Test Alerts"

  folder_uid = "grafana-folder-uid"

  # Use the provisioned datasource UID for better performance
  datasource_uid  = "prometheus-uid-prod"
  datasource_type = "prometheus"

  slack_api_token = var.slack_api_token
  slack_channel   = var.slack_channel

  prometheus_alerts = [
    {
      name         = "High CPU Usage Test"
      metric_expr  = "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
      operator     = ">"
      threshold    = 80
      severity     = "warning"
      description  = "CPU usage is above 80% threshold"
      slack_labels = ["instance", "job"]  # Show which server and job in Slack
    },
    {
      name        = "Node Exporter Down"
      metric_expr = "up{job=\"node-exporter\"}"
      operator    = "=="
      threshold   = 0
      severity    = "critical"
      description = "Node exporter service is not responding and monitoring data may be unavailable"
    },
    {
      name         = "High Memory Usage Test"
      metric_expr  = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
      runbook_url  = "https://example.com/runbooks/high-memory-usage"
      operator     = ">"
      threshold    = 90
      severity     = "warning"
      description  = "Memory usage is above 90% threshold and may cause performance issues"
      slack_labels = ["instance"]  # Only show the server name
    },
    # This will always fire for testing purposes
    {
      name        = "Test Alert - Always Firing"
      metric_expr = "1"
      operator    = "=="
      threshold   = 1
      severity    = "info"
      description = "This alert always fires for testing purposes"
      runbook_url = "https://example.com/runbooks/test-alert"
    }
  ]
}
