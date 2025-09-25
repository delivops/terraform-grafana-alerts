# Example 1: Minimal alerts
module "basic_alerts" {
  source             = "../"
  cluster_name       = "prod"
  folder_uid         = "folder-uid-123"
  rule_group_name    = "Basic Alerts"
  contact_point_name = "OpsGenie"
  
  alerts = [
    {
      name     = "High CPU Usage"
      expr     = "cpu_usage_percent > 80"
      severity = "warning"
    },
    {
      name     = "Database Connection Issues" 
      expr     = "postgres_connections_active / postgres_connections_max > 0.9"
      severity = "critical"
    }
  ]
}

# Example 2: Production alerts with full context
module "production_alerts" {
  source             = "../"
  cluster_name       = "prod-eks"
  folder_uid         = "prod-folder-uid"
  rule_group_name    = "Production Alerts"
  contact_point_name = "PagerDuty"

  # Customize notification timing
  notification_settings = {
    group_by        = ["alertname", "severity", "team"]
    group_wait      = "30s"
    group_interval  = "5m"
    repeat_interval = "4h"
  }

  alerts = [
    {
      name        = "API Response Time High"
      expr        = "histogram_quantile(0.95, http_request_duration_seconds) > 2"
      severity    = "warning"
      description = "API 95th percentile response time is above 2 seconds"
      runbook_url = "https://wiki.company.com/runbooks/api-performance"
      team        = "backend"
      component   = "api"
    },
    {
      name        = "Database Connection Pool Exhausted"
      expr        = "postgres_connection_pool_used / postgres_connection_pool_max > 0.95"
      severity    = "critical"
      description = "Database connection pool is nearly full, may cause timeouts"
      runbook_url = "https://wiki.company.com/runbooks/database"
      team        = "platform"
      component   = "database"
    },
    {
      name        = "Pod Crash Loop"
      expr        = "increase(kube_pod_container_status_restarts_total[15m]) > 3"
      severity    = "critical"
      description = "Pod is restarting frequently"
      team        = "platform"
      component   = "kubernetes"
    }
  ]
}
