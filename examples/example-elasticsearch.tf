# Example: Elasticsearch Alerts Setup
module "elasticsearch_alerts" {
  source = "../"

  rule_group_name = "Elasticsearch Alerts"

  folder_uid = null

  # Use Elasticsearch datasource
  datasource_uid  = "elasticsearch-uid"
  datasource_type = "elasticsearch"

  elasticsearch_alerts = [
{
    name        = "Elasticsearch High Error Rate"
    index       = "elasticsearch-logs"
    query       = "level:ERROR"
    aggregation = {
      field          = "@timestamp"
      id             = "2"
      min_doc_count  = "0"
      order          = "asc"
      orderBy        = "_count"
      size           = "0"
      missing        = ""
      type           = "date_histogram"
      interval       = "1m"
    }
    metric = {
      field               = "_count"
      id                  = "1"
      precision_threshold = ""
      type                = "count"
    }
    operator    = ">"
    threshold   = 1
    pending_for = "10s"
    severity    = "critical"
    description = "Elasticsearch has high error rate (TEST ALERT)"
    team        = "platform"
    component   = "elasticsearch"
  }
  ]
}