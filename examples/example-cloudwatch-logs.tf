# Example: CloudWatch Logs Insights Alerts Setup
module "cloudwatch_logs_alerts" {
  source = "../"

  rule_group_name = "AWS CloudWatch Logs Alerts"

  folder_uid = "grafana-folder-uid"

  # Use CloudWatch datasource
  datasource_uid  = "cloudwatch"
  datasource_type = "cloudwatch"

  cloudwatch_logs_alerts = [
    {
      name        = "OpenSearch Slow Searches"
      log_groups  = ["/aws/opensearch/prod/search-slow"] # Replace with your log group
      query       = "filter @message like /WARN/ | stats count(*) as slow_searches"
      time_range  = 600
      operator    = ">"
      threshold   = 100
      severity    = "warning"
      description = "More than 100 searches took over the slow log warn threshold in the last 10 minutes"
      team        = "search"
      component   = "opensearch"
    },
    {
      # Group by a field: the query must also group by bin() so every group becomes its own series.
      # The bins are not aligned to the time range, so the sum covers the whole range plus part of one bin.
      name         = "OpenSearch Slow Searches By Index"
      log_groups   = ["/aws/opensearch/prod/search-slow"]
      query        = "parse @message /indices\\[(?<index>[^\\]]*)\\]/ | filter @message like /WARN/ | stats count(*) as slow_searches by bin(5m), index"
      stats_groups = ["index"]
      time_range   = 900
      reducer      = "sum" # Sum the 5 minute bins over the time range
      operator     = ">"
      threshold    = 50
      severity     = "warning"
      description  = "More than 50 slow searches on one index in about the last 15 minutes"
      slack_labels = ["index"] # Show which index is slow
    },
    {
      name           = "Application Errors"
      log_groups     = ["/ecs/my-service"] # Replace with your log group
      query          = "filter level = \"error\" | stats count(*) as errors by bin(5m)"
      time_range     = 900
      reducer        = "max"
      operator       = ">"
      threshold      = 10
      severity       = "error"
      description    = "More than 10 errors in a 5 minute window"
      exec_err_state = "KeepLast"
    }
  ]
}
