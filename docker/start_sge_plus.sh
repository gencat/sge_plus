#!/bin/sh
# PRODUCTION deployment script (Linux server).
# Usage: sh docker/start_sge_plus.sh
#
# Prerequisites on the server:
#   - Code cloned in APP_DIR (git clone / git pull)
#   - ENV_FILE filled with real credentials
#   - STORAGE_DIR and LOG_DIR directories created
set -e

IMAGE="sge_plus:latest"
WEB_CONTAINER="sge_plus"
WORKER_CONTAINER="sge_plus_worker"
APP_DIR="/var/www/sge_plus"
ENV_FILE="/var/www/sge_plus/prod.env"
STORAGE_DIR="/var/www/sge_plus/storage"
LOG_DIR="/var/www/sge_plus/log"
OFELIA_INI="/var/www/sge_plus/ofelia.ini"

echo "=== Building image (compiling assets) ==="
docker build -t "$IMAGE" "$APP_DIR"

echo "=== Stopping old containers (if exist) ==="
docker stop "$WEB_CONTAINER"    2>/dev/null || true
docker rm   "$WEB_CONTAINER"    2>/dev/null || true
docker stop "$WORKER_CONTAINER" 2>/dev/null || true
docker rm   "$WORKER_CONTAINER" 2>/dev/null || true

echo "=== Starting worker container (migrations + delayed_jobs) ==="
docker run -d \
  --name "$WORKER_CONTAINER" \
  --restart unless-stopped \
  --network host \
  --env-file "$ENV_FILE" \
  -e RAILS_ENV=production \
  -v "$STORAGE_DIR:/var/www/sge_plus/storage" \
  -v "$LOG_DIR:/var/www/sge_plus/log" \
  "$IMAGE" \
  /bin/sh docker/run-worker.sh

echo "=== Starting web container (puma) ==="
docker run -d \
  --name "$WEB_CONTAINER" \
  --restart unless-stopped \
  --network host \
  --env-file "$ENV_FILE" \
  -e RAILS_ENV=production \
  -e PORT=3000 \
  -v "$STORAGE_DIR:/var/www/sge_plus/storage" \
  -v "$LOG_DIR:/var/www/sge_plus/log" \
  "$IMAGE" \
  /bin/sh docker/run-web_service.sh

echo "=== Restarting Ofelia ==="
docker stop ofelia 2>/dev/null || true
docker rm   ofelia 2>/dev/null || true

docker run -d \
  --name ofelia \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v "$OFELIA_INI:/etc/ofelia/config.ini:ro" \
  mcuadros/ofelia:latest \
  daemon --config=/etc/ofelia/config.ini

echo ""
echo "=== Ready ==="
echo "Web logs:    docker logs -f $WEB_CONTAINER"
echo "Worker logs: docker logs -f $WORKER_CONTAINER"
echo "Crons logs:  docker logs -f ofelia"
