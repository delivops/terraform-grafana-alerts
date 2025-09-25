terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }
}

data "grafana_data_source" "prometheus" {
  name = var.cluster_name
}

locals {
  severity_map = {
    "critical" = "P1"
    "error"    = "P2"
    "warning"  = "P3"
    "info"     = "P4"
  }
}
