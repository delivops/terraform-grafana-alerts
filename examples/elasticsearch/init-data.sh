#!/bin/sh

echo "Waiting for Elasticsearch to be ready..."
until curl -s http://elasticsearch:9200/_cluster/health | grep -q '"status":"green\|"status":"yellow"'; do
  echo "Elasticsearch not ready yet..."
  sleep 5
done

echo "Elasticsearch is ready. Refreshing test data..."

# Delete index if it exists, then create it
curl -X DELETE "http://elasticsearch:9200/elasticsearch-logs" 2>/dev/null || true

# Create index with mappings
curl -X PUT "http://elasticsearch:9200/elasticsearch-logs" \
  -H 'Content-Type: application/json' \
  -d '{
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "level": { "type": "keyword" },
        "message": { "type": "text" },
        "service": { "type": "keyword" },
        "host": { "type": "keyword" }
      }
    }
  }'

# Create temporary file for bulk data
CAT_FILE=$(mktemp)

for i in $(seq 0 10); do
  # Format timestamp for i minutes ago
  TIMESTAMP=$(date -u -d "$i minutes ago" +"%Y-%m-%dT%H:%M:%SZ")
  
  # Add 10 logs for each minute
  for j in $(seq 1 10); do
    echo "{\"index\":{\"_index\":\"elasticsearch-logs\",\"_id\":\"err_${i}_${j}\"}}" >> $CAT_FILE
    echo "{\"@timestamp\":\"$TIMESTAMP\",\"level\":\"ERROR\",\"message\":\"Test error log $i-$j\",\"service\":\"web-server\",\"host\":\"web-01\"}" >> $CAT_FILE
  done
done

# Bulk insert
curl -X POST "http://elasticsearch:9200/elasticsearch-logs/_bulk" \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @$CAT_FILE

rm $CAT_FILE

echo "Test data added successfully! Spread across the last 10 minutes."
echo "Total documents: $(curl -s http://elasticsearch:9200/elasticsearch-logs/_count | jq .count)"
echo "Elasticsearch initialization complete."