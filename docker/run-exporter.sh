#!/bin/sh
set -e

echo "[run-exporter] Starting Prometheus Exporter..."
exec bundle exec prometheus_exporter -b 0.0.0.0 -a lib/prometheus_exporter/server/solid_queue_collector.rb
