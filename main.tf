terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }
}

data "grafana_data_source" "datasource" {
  count = var.datasource_uid == null ? 1 : 0
  name  = var.datasource_name
}

locals {
  # Use provided UID or lookup by name
  datasource_uid = var.datasource_uid != null ? var.datasource_uid : data.grafana_data_source.datasource[0].uid

  severity_map = {
    "critical" = "P1"
    "error"    = "P2"
    "warning"  = "P3"
    "info"     = "P4"
  }
}
