variable "slack_api_token" {
  description = "Slack Bot User OAuth Token (xoxb-...). Get from https://api.slack.com/apps"
  type        = string
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel to send alerts to (with # prefix, e.g., #alerts)"
  type        = string
}

variable "cloudwatch_datasource_uid" {
  description = "UID of the CloudWatch datasource in Grafana"
  type        = string
}