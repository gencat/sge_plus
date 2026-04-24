#!/bin/sh
# Script de despliegue PRODUCCIÓN (servidor Linux).
# Uso: sh docker/start_sge_plus.sh
#
# Prerequisitos en el servidor:
#   - Código clonado en APP_DIR (git clone / git pull)
#   - Fichero ENV_FILE relleno con credenciales reales
#   - Directorios STORAGE_DIR y LOG_DIR creados
set -e

IMAGE="sge_plus:latest"
CONTAINER="sge_plus"
APP_DIR="/srv/sge_plus/app"
ENV_FILE="/srv/sge_plus/prod.env"
STORAGE_DIR="/srv/sge_plus/storage"
LOG_DIR="/srv/sge_plus/log"
OFELIA_INI="/srv/sge_plus/ofelia.ini"

echo "=== Construyendo imagen (compilando assets) ==="
docker build -t "$IMAGE" "$APP_DIR"

echo "=== Ejecutando migraciones ==="
docker run --rm \
  --network host \
  --env-file "$ENV_FILE" \
  -e RAILS_ENV=production \
  "$IMAGE" \
  bundle exec rails db:migrate

echo "=== Parando contenedor antiguo (si existe) ==="
docker stop "$CONTAINER" 2>/dev/null || true
docker rm   "$CONTAINER" 2>/dev/null || true

echo "=== Arrancando contenedor web ==="
docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  --network host \
  --env-file "$ENV_FILE" \
  -e RAILS_ENV=production \
  -e PORT=3000 \
  -v "$STORAGE_DIR:/var/www/sge_plus/storage" \
  -v "$LOG_DIR:/var/www/sge_plus/log" \
  "$IMAGE" \
  /bin/sh -c "docker/run-web_service.sh"

echo "=== Reiniciando Ofelia ==="
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
echo "=== Listo ==="
echo "Logs web:   docker logs -f $CONTAINER"
echo "Logs crons: docker logs -f ofelia"
