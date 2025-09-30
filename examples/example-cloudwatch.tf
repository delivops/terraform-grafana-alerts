# Example: CloudWatch Alerts Setup
module "cloudwatch_alerts" {
  source = "../"

  rule_group_name = "AWS CloudWatch Alerts"

  folder_uid = "grafana-folder-uid"

  # Use CloudWatch datasource
  datasource_uid  = "cloudwatch"
  datasource_type = "cloudwatch"

  cloudwatch_alerts = [
    {
      name        = "EC2 Instance Status Check Failed"
      namespace   = "AWS/EC2"
      metric_name = "StatusCheckFailed_Instance"
      dimensions = {
        InstanceId = "i-0123456789abcdef0"  # Replace with your EC2 instance ID
      }
      statistic   = "Sum"
      period      = "300"
      region      = "default"
      operator    = ">"
      threshold   = 0
      severity    = "critical"
      description = "EC2 instance has failed status checks"
      runbook_url = "https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html"
      team        = "infrastructure"
      component   = "compute"
      slack_labels = ["InstanceId"]  # Show which instance failed
    },
    {
      name        = "High CPU Utilization"
      namespace   = "AWS/EC2"
      metric_name = "CPUUtilization"
      dimensions = {
        InstanceId = "i-0123456789abcdef0"  # Replace with your EC2 instance ID
      }
      statistic   = "Average"
      period      = "300"
      region      = "default"
      reducer     = "mean"  # Use mean for CPU utilization over the time window
      operator    = ">"
      threshold   = 80
      severity    = "warning"
      description = "EC2 instance CPU utilization is above 80%"
      team        = "infrastructure"
      component   = "compute"
    },
    {
      name        = "RDS High CPU"
      namespace   = "AWS/RDS"
      metric_name = "CPUUtilization"
      dimensions = {
        DBInstanceIdentifier = "prod-db-instance"  # Replace with your RDS instance ID
      }
      statistic   = "Average"
      period      = "300"
      region      = "default"
      operator    = ">"
      threshold   = 80
      severity    = "warning"
      description = "RDS instance CPU utilization is above 80%"
      team        = "database"
      component   = "rds"
      slack_labels = ["DBInstanceIdentifier"]  # Show which database instance
    },
    {
      name        = "RDS Low Available Memory"
      namespace   = "AWS/RDS"
      metric_name = "FreeableMemory"
      dimensions = {
        DBInstanceIdentifier = "prod-db-instance"  # Replace with your RDS instance ID
      }
      statistic   = "Average"
      period      = "300"
      region      = "default"
      reducer     = "min"  # Use minimum value to catch the lowest memory point
      operator    = "<"
      threshold   = 1073741824  # 1GB in bytes
      severity    = "critical"
      description = "RDS instance has less than 1GB of available memory"
      team        = "database"
      component   = "rds"
    },
    {
      name        = "ELB High Response Time"
      namespace   = "AWS/ApplicationELB"
      metric_name = "TargetResponseTime"
      dimensions = {
        LoadBalancer = "my-load-balancer"  # Replace with your Load Balancer name
      }
      statistic   = "Average"
      period      = "300"
      region      = "default"
      operator    = ">"
      threshold   = 2
      severity    = "warning"
      description = "Application Load Balancer response time is above 2 seconds"
      team        = "platform"
      component   = "loadbalancer"
    }
  ]
}