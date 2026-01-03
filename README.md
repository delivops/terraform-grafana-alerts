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

### Basic Usage (Prometheus)

```hcl
module "basic_alerts" {
  source             = "delivops/grafana-alerts/grafana"
  version            = "1.0.0"

  folder_uid         = "grafana-folder-uid"
  rule_group_name    = "Basic Alerts"
  contact_point_name = "OpsGenie"
  datasource_type    = "prometheus"
  
  alerts = [
    {
      name        = "High CPU Usage"
      metric_expr = "cpu_usage_percent"
      operator    = ">"
      threshold   = 80
      severity    = "warning"
    },
    {
      name        = "Database Connection Issues"
      metric_expr = "postgres_connections_active / postgres_connections_max"
      operator    = ">"
      threshold   = 0.9
      severity    = "critical"
    }
  ]
}
```

### Basic Usage (CloudWatch)

```hcl
module "cloudwatch_alerts" {
  source             = "delivops/grafana-alerts/grafana"
  version            = "1.0.0"

  folder_uid         = "grafana-folder-uid"
  rule_group_name    = "AWS Alerts"
  contact_point_name = "OpsGenie"
  datasource_type    = "cloudwatch"
  
  alerts = [
    {
      name        = "EC2 Instance Status Check Failed"
      namespace   = "AWS/EC2"
      metric_name = "StatusCheckFailed_Instance"
      dimensions = {
        InstanceId = "i-00dd2460aa9528157"
      }
      statistic   = "Sum"
      period      = "300"
      region      = "us-east-1"
      operator    = ">"
      threshold   = 0
      severity    = "critical"
    },
    {
      name        = "High CPU Utilization"
      namespace   = "AWS/EC2"
      metric_name = "CPUUtilization"
      dimensions = {
        InstanceId = "i-00dd2460aa9528157"
      }
      statistic   = "Average"
      period      = "300"
      operator    = ">"
      threshold   = 80
      severity    = "warning"
    }
  ]
}
```

### Production Usage (Prometheus)

```hcl
module "production_alerts" {
  source             = "delivops/grafana-alerts/grafana"
  version            = "1.0.0"

  folder_uid         = "prod-folder-uid"
  rule_group_name    = "Production Alerts"
  contact_point_name = "PagerDuty"
  datasource_type    = "prometheus"

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
      metric_expr = "histogram_quantile(0.95, http_request_duration_seconds)"
      operator    = ">"
      threshold   = 2
      severity    = "warning"
      description = "API 95th percentile response time is above 2 seconds"
      runbook_url = "https://wiki.company.com/runbooks/api-performance"
      team        = "backend"
      component   = "api"
    },
    {
      name        = "Database Connection Pool Exhausted"
      metric_expr = "postgres_connection_pool_used / postgres_connection_pool_max"
      operator    = ">"
      threshold   = 0.95
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

## Alert Configuration

This module supports both **Prometheus** and **CloudWatch** datasources with different configuration patterns:

### Prometheus Alerts
For Prometheus datasources, provide:
- **metric_expr**: Prometheus query expression (e.g., `cpu_usage_percent`, `rate(http_requests_total[5m])`)

### CloudWatch Alerts  
For CloudWatch datasources, provide:
- **namespace**: AWS namespace (e.g., `AWS/EC2`, `AWS/RDS`)
- **metric_name**: CloudWatch metric name (e.g., `CPUUtilization`, `StatusCheckFailed`)
- **dimensions**: Key-value map of dimensions (e.g., `{InstanceId = "i-123"}`)
- **statistic**: Aggregation method (`Average`, `Sum`, `Maximum`, `Minimum`)
- **period**: Aggregation period in seconds (default: `"300"`)
- **region**: AWS region (default: `"default"`)

## Alert Fields

### Required (All Datasources)
- **name**: Alert name (will appear in notifications)
- **operator**: Comparison operator (`>`, `<`, `>=`, `<=`, `==`, `!=`)
- **threshold**: Threshold value for comparison
- **severity**: `critical`, `error`, `warning`, or `info`

### Required (Prometheus)
- **metric_expr**: Prometheus query expression

### Required (CloudWatch)
- **namespace**: AWS namespace
- **metric_name**: CloudWatch metric name

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
| [grafana_contact_point.slack](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/contact_point) | resource |
| [grafana_folder.folder](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/folder) | resource |
| [grafana_rule_group.alerts](https://registry.terraform.io/providers/grafana/grafana/latest/docs/resources/rule_group) | resource |
| [grafana_data_source.datasource](https://registry.terraform.io/providers/grafana/grafana/latest/docs/data-sources/data_source) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_alerts"></a> [cloudwatch\_alerts](#input\_cloudwatch\_alerts) | List of CloudWatch alert configurations | <pre>list(<br/>    object({<br/>      name           = string<br/>      namespace      = string                # AWS namespace (e.g., AWS/EC2)<br/>      metric_name    = string                # CloudWatch metric name<br/>      dimensions     = optional(map(string), {}) # CloudWatch dimensions<br/>      statistic      = optional(string, "Average") # CloudWatch statistic (Sum, Average, Maximum, etc.)<br/>      period         = optional(string, "300") # CloudWatch period in seconds<br/>      region         = optional(string, "default") # CloudWatch region<br/>      reducer        = optional(string, "last") # Reducer function (last, mean, max, min, sum, count, etc.)<br/>      operator       = optional(string, ">") # >, <, ==, !=, >=, <=<br/>      threshold      = number                # Threshold value<br/>      severity       = string<br/>      description    = optional(string, null)<br/>      runbook_url    = optional(string, null)<br/>      team           = optional(string, null)<br/>      component      = optional(string, null)<br/>      slack_labels   = optional(list(string), []) # CloudWatch dimensions to show in Slack (e.g., ["InstanceId", "AutoScalingGroupName"])<br/>      pending_for    = optional(string, "5m")<br/>      no_data_state  = optional(string, "Alerting")<br/>      exec_err_state = optional(string, "Alerting")<br/>    })<br/>  )</pre> | `[]` | no |
| <a name="input_contact_point_name"></a> [contact\_point\_name](#input\_contact\_point\_name) | Name of the contact point to use for notifications. Required if not creating a new Slack contact point. | `string` | `null` | no |
| <a name="input_datasource_name"></a> [datasource\_name](#input\_datasource\_name) | Name of the Grafana datasource to use for alerts | `string` | `null` | no |
| <a name="input_datasource_type"></a> [datasource\_type](#input\_datasource\_type) | Type of the datasource (e.g., prometheus, loki, influxdb, etc.) | `string` | `"prometheus"` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | UID of the Grafana datasource to use for alerts (takes precedence over datasource\_name) | `string` | `null` | no |
| <a name="input_elasticsearch_alerts"></a> [elasticsearch\_alerts](#input\_elasticsearch\_alerts) | List of Elasticsearch alert configurations | <pre>list(<br/>    object({<br/>      name           = string<br/>      index          = string                # Elasticsearch index<br/>      query          = string                # Elasticsearch query<br/>      operator       = optional(string, ">") # >, <, ==, !=, >=, <=<br/>      threshold      = number                # Threshold value<br/>      severity       = string<br/>      description    = optional(string, null)<br/>      runbook_url    = optional(string, null)<br/>      team           = optional(string, null)<br/>      component      = optional(string, null)<br/>      slack_labels   = optional(list(string), []) # Elasticsearch labels to show in Slack (e.g., ["index", "type", "id"])<br/>      pending_for    = optional(string, "5m")<br/>      no_data_state  = optional(string, "Alerting")<br/>      exec_err_state = optional(string, "Alerting")<br/>      aggregation = object({<br/>        field         = string<br/>        id            = string<br/>        min_doc_count = string<br/>        order         = string<br/>        orderBy       = string<br/>        size          = string<br/>        missing       = string<br/>        type          = string<br/>        interval      = optional(string, "auto")<br/>      })<br/>      metric = object({<br/>        field               = optional(string, null)<br/>        id                  = string<br/>        precision_threshold = optional(string, null)<br/>        type                = string<br/>      })<br/>    })<br/>  )</pre> | `[]` | no |
| <a name="input_folder_uid"></a> [folder\_uid](#input\_folder\_uid) | Uid of the Grafana folder to place the rule group in. If null, a new folder named after the rule\_group\_name will be created. | `string` | `null` | no |
| <a name="input_notification_settings"></a> [notification\_settings](#input\_notification\_settings) | Notification settings for alerts | <pre>object({<br/>    group_by        = optional(list(string), ["alertname", "cluster", "severity"])<br/>    group_wait      = optional(string, "30s")<br/>    group_interval  = optional(string, "5m")<br/>    repeat_interval = optional(string, "4h")<br/>  })</pre> | <pre>{<br/>  "group_by": [<br/>    "alertname",<br/>    "cluster",<br/>    "severity"<br/>  ],<br/>  "group_interval": "5m",<br/>  "group_wait": "30s",<br/>  "repeat_interval": "4h"<br/>}</pre> | no |
| <a name="input_prometheus_alerts"></a> [prometheus\_alerts](#input\_prometheus\_alerts) | List of Prometheus alert configurations | <pre>list(<br/>    object({<br/>      name           = string<br/>      metric_expr    = string                # Prometheus query expression<br/>      operator       = optional(string, ">") # >, <, ==, !=, >=, <=<br/>      threshold      = number                # Threshold value<br/>      severity       = string<br/>      description    = optional(string, null)<br/>      runbook_url    = optional(string, null)<br/>      team           = optional(string, null)<br/>      component      = optional(string, null)<br/>      slack_labels   = optional(list(string), []) # Prometheus labels to show in Slack (e.g., ["instance", "job", "service"])<br/>      pending_for    = optional(string, "5m")<br/>      no_data_state  = optional(string, "Alerting")<br/>      exec_err_state = optional(string, "Alerting")<br/>    })<br/>  )</pre> | `[]` | no |
| <a name="input_rule_group_name"></a> [rule\_group\_name](#input\_rule\_group\_name) | Name of the rule group | `string` | n/a | yes |
| <a name="input_slack_api_token"></a> [slack\_api\_token](#input\_slack\_api\_token) | Slack Bot User OAuth Token (xoxb-...). Get from https://api.slack.com/apps | `string` | `null` | no |
| <a name="input_slack_channel"></a> [slack\_channel](#input\_slack\_channel) | Slack channel to send alerts to (with # prefix, e.g., #alerts) | `string` | `"#alerts"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_count"></a> [alert\_count](#output\_alert\_count) | Number of alerts configured |
| <a name="output_cloudwatch_alert_count"></a> [cloudwatch\_alert\_count](#output\_cloudwatch\_alert\_count) | Number of CloudWatch alerts configured |
| <a name="output_configured_alerts"></a> [configured\_alerts](#output\_configured\_alerts) | List of configured alert names |
| <a name="output_datasource_uid"></a> [datasource\_uid](#output\_datasource\_uid) | UID of the datasource used for alerts |
| <a name="output_elasticsearch_alert_count"></a> [elasticsearch\_alert\_count](#output\_elasticsearch\_alert\_count) | Number of Elasticsearch alerts configured |
| <a name="output_prometheus_alert_count"></a> [prometheus\_alert\_count](#output\_prometheus\_alert\_count) | Number of Prometheus alerts configured |
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

### Prometheus Monitoring
```hcl
alerts = [
  {
    name        = "High Memory Usage"
    metric_expr = "memory_usage_percent"
    operator    = ">"
    threshold   = 85
    severity    = "warning"
  }
]
```

### CloudWatch Monitoring
```hcl
alerts = [
  {
    name        = "RDS High CPU"
    namespace   = "AWS/RDS"
    metric_name = "CPUUtilization"
    dimensions = {
      DBInstanceIdentifier = "production-db"
    }
    statistic   = "Average"
    operator    = ">"
    threshold   = 80
    severity    = "warning"
  }
]
```

### Elasticsearch Monitoring
```hcl
alerts = [
  {
    name        = "Elasticsearch High Error Rate"
    index       = "elasticsearch-*"
    query       = "level:ERROR"
    aggregation = {
      field          = "@timestamp"
      id             = "2"
      min_doc_count  = "1"
      order          = "desc"
      orderBy        = "_count"
      size           = "0"
      missing        = ""
      type           = "date_histogram"
    }
    metric = {
      field               = "_count"
      id                  = "1"
      precision_threshold = ""
      type                = "count"
    }
    operator    = ">"
    threshold   = 100
    severity    = "warning"
    description = "Elasticsearch has high error rate in the last 5 minutes"
    team        = "platform"
    component   = "elasticsearch"
  },
  {
    name        = "Elasticsearch Slow Query Performance"
    index       = "elasticsearch-*"
    query       = "took:[5000 TO *]"
    aggregation = {
      field          = "@timestamp"
      id             = "2"
      min_doc_count  = "1"
      order          = "desc"
      orderBy        = "_count"
      size           = "0"
      missing        = ""
      type           = "date_histogram"
    }
    metric = {
      field               = "took"
      id                  = "1"
      precision_threshold = ""
      type                = "avg"
    }
    operator    = ">"
    threshold   = 5000
    severity    = "warning"
    description = "Average Elasticsearch query time exceeds 5 seconds"
    team        = "platform"
    component   = "elasticsearch"
  }
]
```

### Production-Ready Alert
```hcl
alerts = [
  {
    name        = "Database Slow Queries"
    metric_expr = "mysql_slow_queries_rate"
    operator    = ">"
    threshold   = 10
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
