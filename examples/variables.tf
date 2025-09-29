variable "slack_api_token" {
  description = "Slack Bot User OAuth Token (xoxb-...). Get from https://api.slack.com/apps"
  type        = string
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel to send alerts to (with # prefix, e.g., #alerts)"
  type        = string
}

variable "grafana_api_key" {
  description = "Grafana API Key for authentication (not needed for local Docker testing)"
  type        = string
  default     = "not-needed-for-local-testing"
  sensitive   = true
}