output "rule_group_id" {
  description = "The ID of the created rule group"
  value       = (length(var.prometheus_alerts) + length(var.cloudwatch_alerts) + length(var.elasticsearch_alerts)) > 0 ? grafana_rule_group.alerts[0].id : null
}

output "rule_group_name" {
  description = "The name of the created rule group"
  value       = (length(var.prometheus_alerts) + length(var.cloudwatch_alerts) + length(var.elasticsearch_alerts)) > 0 ? grafana_rule_group.alerts[0].name : null
}

output "alert_count" {
  description = "Number of alerts configured"
  value       = length(var.prometheus_alerts) + length(var.cloudwatch_alerts) + length(var.elasticsearch_alerts)
}

output "prometheus_alert_count" {
  description = "Number of Prometheus alerts configured"
  value       = length(var.prometheus_alerts)
}

output "cloudwatch_alert_count" {
  description = "Number of CloudWatch alerts configured"
  value       = length(var.cloudwatch_alerts)
}

output "elasticsearch_alert_count" {
  description = "Number of Elasticsearch alerts configured"
  value       = length(var.elasticsearch_alerts)
}

output "configured_alerts" {
  description = "List of configured alert names"
  value = concat(
    [for alert in var.prometheus_alerts : alert.name],
    [for alert in var.cloudwatch_alerts : alert.name],
    [for alert in var.elasticsearch_alerts : alert.name]
  )
}

output "datasource_uid" {
  description = "UID of the datasource used for alerts"
  value       = local.datasource_uid
}