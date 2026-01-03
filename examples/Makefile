.PHONY: start stop test clean logs status

# Start the Docker Compose stack
start:
	docker-compose up -d
	@echo "Waiting for services to start..."
	@echo "✅ Stack started! Grafana: http://localhost:3000 (admin/admin)"

# Stop the stack
stop:
	docker-compose down

# Full test cycle
test: start
	@echo "🚀 Running Terraform tests..."
	terraform init
	terraform plan
	terraform apply -auto-approve
	@echo "✅ Alerts deployed! Check http://localhost:3000/alerting/list"

# Clean everything
clean:
	terraform destroy -auto-approve || true
	docker-compose down -v
	docker system prune -f

# View logs
logs:
	docker-compose logs -f

# Check status
status:
	@echo "=== Docker Services ==="
	docker-compose ps
	@echo ""
	@echo "=== Grafana Health ==="
	@curl -s http://localhost:3000/api/health | jq . || echo "Grafana not responding"
	@echo ""
	@echo "=== Prometheus Targets ==="
	@curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}' || echo "Prometheus not responding"

# Quick demo
demo: test
	@echo ""
	@echo "🎯 Demo Environment Ready!"
	@echo "📊 Grafana UI: http://localhost:3000 (admin/admin)"
	@echo "📈 Prometheus: http://localhost:9090"
	@echo "🔍 Elasticsearch: http://localhost:9200"
	@echo "⚡ Node Exporter: http://localhost:9100/metrics"
	@echo ""
	@echo "📋 Check your alerts at: http://localhost:3000/alerting/list"
	@echo "📊 Explore Elasticsearch data at: http://localhost:3000/explore (select Elasticsearch datasource)"