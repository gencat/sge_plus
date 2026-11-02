#!/bin/sh
# Script de despliegue LOCAL (Docker Desktop).
# Uso: sh docker/development/start_local.sh
set -e

IMAGE="sge_plus:latest"
WEB_CONTAINER="sge_plus"
WORKER_CONTAINER="sge_plus_worker"
EXPORTER_CONTAINER="sge_plus_exporter"
APP_DIR="$(pwd)"
ENV_FILE="$(pwd)/docker/local.env"
STORAGE_DIR="$(pwd)/storage"
LOG_DIR="$(pwd)/log"

echo "=== Construyendo imagen (compilando assets) ==="
docker build -t "$IMAGE" "$APP_DIR"

echo "=== Parando contenedores antiguos (si existen) ==="
docker stop "$WEB_CONTAINER"      2>/dev/null || true
docker rm   "$WEB_CONTAINER"      2>/dev/null || true
docker stop "$WORKER_CONTAINER"   2>/dev/null || true
docker rm   "$WORKER_CONTAINER"   2>/dev/null || true
docker stop "$EXPORTER_CONTAINER" 2>/dev/null || true
docker rm   "$EXPORTER_CONTAINER" 2>/dev/null || true

echo "=== Arrancando contenedor worker (migraciones + Solid Queue) ==="
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

echo "=== Arrancando contenedor web (puma) ==="
docker run -d \
  --name "$WEB_CONTAINER" \
  --restart unless-stopped \
  --network host \
  --env-file "$ENV_FILE" \
  -e RAILS_ENV=production \
  -e PORT=3000 \
  -e RAILS_SERVE_STATIC_FILES=true \
  -v "$STORAGE_DIR:/var/www/sge_plus/storage" \
  -v "$LOG_DIR:/var/www/sge_plus/log" \
  "$IMAGE" \
  /bin/sh docker/run-web_service.sh

echo "=== Arrancando contenedor Prometheus Exporter ==="
docker run -d \
  --name "$EXPORTER_CONTAINER" \
  --restart unless-stopped \
  --network host \
  --env-file "$ENV_FILE" \
  -e RAILS_ENV=production \
  "$IMAGE" \
  /bin/sh docker/run-exporter.sh

echo ""
echo "=== Listo ==="
echo "Web logs:      docker logs -f $WEB_CONTAINER"
echo "Worker logs:   docker logs -f $WORKER_CONTAINER"
echo "Exporter logs: docker logs -f $EXPORTER_CONTAINER"
echo "Web:           http://localhost:3000"
echo "Metricas:      http://localhost:9394/metrics"
