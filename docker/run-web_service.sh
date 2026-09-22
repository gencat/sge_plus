#!/bin/sh
set -e

APP_DIR="/var/www/sge_plus"

echo "[run-web_service] Removing stale PID file if present..."
rm -f "$APP_DIR/tmp/pids/server.pid"

echo "[run-web_service] Starting Puma..."
exec bundle exec puma -C config/puma.rb
