[![DelivOps banner](https://raw.githubusercontent.com/delivops/.github/main/images/banner.png?raw=true)](https://delivops.com)

# terraform-grafana-alerts

A **simple but production-grade** Terraform module for creating Grafana alert rules. This module is opinionated by design, providing sensible defaults while allowing essential customization for production environments.

## Philosophy

🎯 **Opinionated by design** - We've made the hard decisions so you don't have to  
🚀 **Production-ready out of the box** - Includes team context, runbook links, and proper labeling  
📝 **Simple interface** - Only expose what you actually need to customize  
🧹 **Clean & focused** - No legacy cruft or backward compatibility compromises

## Features

✅ **Minimal Configuration**: Get started with just name, expr, and severity  
✅ **Production Context**: Built-in support for descriptions, runbooks, team info  
✅ **Smart Defaults**: Opinionated settings that work well in production  
✅ **Team Routing**: Assign alerts to teams and components  
✅ **Notification Control**: Simple notification timing customization  

## Installation

```bash
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }
}
```

## Usage

### Basic Usage

```hcl
module "basic_alerts" {
  source             = "delivops/grafana-alerts/grafana"
  version            = "1.0.0"

  folder_uid         = "grafana-folder-uid"
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
```

### Production Usage

```hcl
module "production_alerts" {
  source             = "delivops/grafana-alerts/grafana"
  version            = "1.0.0"

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
      description = "Database connection pool is nearly full"
      runbook_url = "https://wiki.company.com/runbooks/database"
      team        = "platform"
      component   = "database"
    }
  ]
}
```

## Opinionated Defaults

This module makes sensible choices so you don't have to:

| Setting | Default Value | Reasoning |
|---------|---------------|-----------|
| **Alert Duration** | `5m` | Long enough to avoid flapping |
| **Evaluation Interval** | `60s` | Good balance of responsiveness vs load |
| **No Data State** | `OK` | Most alerts shouldn't fire on missing data |
| **Grouping** | `["alertname", "cluster", "severity"]` | Logical grouping for most scenarios |
| **Group Wait** | `45s` | Allow time for related alerts to group |
| **Repeat Interval** | `12h` | Aggressive enough for production |

## Alert Fields

### Required
- **name**: Alert name (will appear in notifications)
- **expr**: Prometheus query expression
- **severity**: `critical`, `error`, `warning`, or `info`

### Production Enhancements (Optional)
- **description**: Human-readable alert context
- **runbook_url**: Link to troubleshooting procedures  
- **team**: Which team owns this alert (default: "platform")
- **component**: What component this monitors (default: "system")

## Automatic Labels & Annotations

Every alert automatically gets:

**Labels:**
- `severity` - Your specified severity level
- `priority` - Auto-mapped priority (P1-P4)
- `cluster` - Your cluster name
- `team` - Team owner (from alert or default "platform")
- `component` - Component name (from alert or default "system")

**Annotations:**
- `description` - Your description or auto-generated summary
- `summary` - Clean alert name
- `runbook_url` - Your runbook or default Grafana alerting page

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 3.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_grafana"></a> [grafana](#provider\_grafana) | >= 3.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [grafana_rule_group.alerts](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/rule_group) | resource |
| [grafana_data_source.prometheus](https://registry.terraform.io/providers/grafana/grafana/latest/docs/data-sources/data_source) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | List of alert configurations | <pre>list(<br/>    object({<br/>      name        = string<br/>      expr        = string<br/>      severity    = string<br/>      description = optional(string, null)<br/>      runbook_url = optional(string, null)<br/>      team        = optional(string, null)<br/>      component   = optional(string, null)<br/>    })<br/>  )</pre> | n/a | yes |
| <a name="input_contact_point_name"></a> [contact\_point\_name](#input\_contact\_point\_name) | Name of the contact point | `string` | n/a | yes |
| <a name="input_folder_uid"></a> [folder\_uid](#input\_folder\_uid) | Uid of the Grafana folder | `string` | n/a | yes |
| <a name="input_grafana_api_key"></a> [grafana\_api\_key](#input\_grafana\_api\_key) | Grafana API key with permissions to manage alerting | `string` | n/a | yes |
| <a name="input_grafana_url"></a> [grafana\_url](#input\_grafana\_url) | Base URL for Grafana instance | `string` | `"https://grafana.company.com"` | no |
| <a name="input_notification_settings"></a> [notification\_settings](#input\_notification\_settings) | Notification settings for alerts | <pre>object({<br/>    group_by        = optional(list(string), ["alertname", "cluster", "severity"])<br/>    group_wait      = optional(string, "45s")<br/>    group_interval  = optional(string, "6m")<br/>    repeat_interval = optional(string, "12h")<br/>  })</pre> | <pre>{<br/>  "group_by": [<br/>    "alertname",<br/>    "cluster",<br/>    "severity"<br/>  ],<br/>  "group_interval": "6m",<br/>  "group_wait": "45s",<br/>  "repeat_interval": "12h"<br/>}</pre> | no |
| <a name="input_rule_group_name"></a> [rule\_group\_name](#input\_rule\_group\_name) | Name of the rule group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_count"></a> [alert\_count](#output\_alert\_count) | Number of alerts configured |
| <a name="output_configured_alerts"></a> [configured\_alerts](#output\_configured\_alerts) | List of configured alert names |
| <a name="output_prometheus_datasource_uid"></a> [prometheus\_datasource\_uid](#output\_prometheus\_datasource\_uid) | UID of the Prometheus datasource used |
| <a name="output_rule_group_id"></a> [rule\_group\_id](#output\_rule\_group\_id) | The ID of the created rule group |
| <a name="output_rule_group_name"></a> [rule\_group\_name](#output\_rule\_group\_name) | The name of the created rule group |
<!-- END_TF_DOCS -->

## Severity Levels and Priorities

The module automatically maps severity levels to standard priorities:

| Severity | Priority |
|----------|----------|
| critical | P1       |
| error    | P2       |
| warning  | P3       |
| info     | P4       |

## Best Practices

1. **Use Descriptive Names**: Choose clear, actionable alert names
2. **Include Context**: Use descriptions to provide troubleshooting context
3. **Set Appropriate Teams**: Assign alerts to the right teams for quick response
4. **Document Runbooks**: Always include `runbook_url` for complex alerts
5. **Test Thresholds**: Validate alert thresholds in staging first

## Examples

### Simple Monitoring
```hcl
alerts = [
  {
    name     = "High Memory Usage"
    expr     = "memory_usage_percent > 85"
    severity = "warning"
  }
]
```

### Production-Ready Alert
```hcl
alerts = [
  {
    name        = "Database Slow Queries"
    expr        = "mysql_slow_queries_rate > 10"
    severity    = "critical"
    description = "Database is processing too many slow queries"
    runbook_url = "https://wiki.company.com/db-slow-queries"
    team        = "database"
    component   = "mysql"
  }
]
```

## Troubleshooting

### Common Issues

1. **Alert not firing**: Check Prometheus query syntax and data availability
2. **No notifications**: Verify contact point configuration in Grafana
3. **Wrong team assignment**: Check team labels are correctly set

## License

MIT
