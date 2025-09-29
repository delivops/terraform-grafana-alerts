output "rule_group_id" {
  description = "The ID of the created rule group"
  value       = length(var.alerts) > 0 ? grafana_rule_group.alerts[0].id : null
}

output "rule_group_name" {
  description = "The name of the created rule group"
  value       = length(var.alerts) > 0 ? grafana_rule_group.alerts[0].name : null
}

output "alert_count" {
  description = "Number of alerts configured"
  value       = length(var.alerts)
}

output "configured_alerts" {
  description = "List of configured alert names"
  value       = [for alert in var.alerts : alert.name]
}

output "datasource_uid" {
  description = "UID of the datasource used for alerts"
  value       = local.datasource_uid
}