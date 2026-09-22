#!/bin/sh
set -e

APP_DIR="/var/www/sge_plus"

echo "[run-worker] Removing stale PID file if present..."
rm -f "$APP_DIR/tmp/pids/server.pid"

echo "[run-worker] Running migrations..."
bundle exec rails db:migrate

echo "[run-worker] Starting delayed_jobs..."
exec bundle exec rails jobs:work
