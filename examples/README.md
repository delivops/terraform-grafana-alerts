# Examples

This directory contains example configurations for different datasource types.

## Prometheus Example (Docker Compose)

The `example.tf` file demonstrates setting up alerts with a local Prometheus instance using Docker Compose.

### Usage

1. Start the stack:
   ```bash
   make up
   ```

2. Configure your variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. Apply the configuration:
   ```bash
   terraform init
   terraform apply
   ```

4. View Grafana at http://localhost:3000 (admin/admin)

5. Clean up:
   ```bash
   make down
   ```

## CloudWatch Example

The `cloudwatch-example.tf` file demonstrates setting up alerts with AWS CloudWatch metrics.

### Prerequisites

- Grafana instance with CloudWatch datasource configured
- AWS credentials configured
- Grafana API key with alerting permissions

### Usage

1. Configure your variables:
   ```bash
   cp cloudwatch.tfvars.example cloudwatch.tfvars
   # Edit cloudwatch.tfvars with your AWS resources and Grafana details
   ```

2. Apply the configuration:
   ```bash
   terraform init
   terraform apply -var-file="cloudwatch.tfvars"
   ```

### Required Variables

- `grafana_api_key`: Your Grafana API key
- `grafana_url`: Your Grafana instance URL
- `cloudwatch_datasource_uid`: UID of your CloudWatch datasource in Grafana
- `contact_point_name`: Name of your notification contact point
- `ec2_instance_id`: EC2 instance to monitor
- `rds_instance_id`: RDS instance to monitor
- `alb_name`: Application Load Balancer to monitor

## Configuration Differences

### Prometheus Alerts
```hcl
alerts = [
  {
    name        = "High CPU Usage"
    metric_expr = "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
    operator    = ">"
    threshold   = 80
    severity    = "warning"
  }
]
```

### CloudWatch Alerts
```hcl
alerts = [
  {
    name        = "High CPU Usage"
    namespace   = "AWS/EC2"
    metric_name = "CPUUtilization"
    dimensions = {
      InstanceId = "i-1234567890abcdef0"
    }
    statistic   = "Average"
    operator    = ">"
    threshold   = 80
    severity    = "warning"
  }
]
```