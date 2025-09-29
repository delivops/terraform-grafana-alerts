terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }
}

# Grafana provider configuration for local testing
provider "grafana" {
  url  = "http://localhost:3000"
  auth = "admin:admin"
}
