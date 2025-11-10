#!/bin/bash

###############################################################################
# Script: update-images.sh
# Description: Actualiza las imágenes de Docker en values.yaml
# Usage: ./update-images.sh <docker-username>
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOCKER_USERNAME=$1
VALUES_FILE="helm/comments-system/values.yaml"

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Error: Docker username requerido${NC}"
    echo ""
    echo "Uso: $0 <docker-username>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 juanperez"
    echo ""
    echo "Esto actualizará values.yaml con tus imágenes:"
    echo "  - juanperez/comments-system-frontend:latest"
    echo "  - juanperez/comments-system-backend-api:latest"
    echo "  - juanperez/comments-system-backend-data:latest"
    exit 1
fi

if [ ! -f "$VALUES_FILE" ]; then
    echo -e "${RED}Error: $VALUES_FILE no encontrado${NC}"
    exit 1
fi

echo "========================================"
echo "  Actualizando Imágenes Docker"
echo "========================================"
echo ""
echo "Docker Username: $DOCKER_USERNAME"
echo "Archivo: $VALUES_FILE"
echo ""

# Backup del archivo original
BACKUP_FILE="${VALUES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$VALUES_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓${NC} Backup creado: $BACKUP_FILE"
echo ""

# Actualizar imágenes
echo "Actualizando imágenes..."

# Frontend
sed -i "s|repository: .*/comments-system-frontend|repository: ${DOCKER_USERNAME}/comments-system-frontend|g" "$VALUES_FILE"
echo -e "${GREEN}✓${NC} Frontend: ${DOCKER_USERNAME}/comments-system-frontend"

# Backend API
sed -i "s|repository: .*/comments-system-backend-api|repository: ${DOCKER_USERNAME}/comments-system-backend-api|g" "$VALUES_FILE"
echo -e "${GREEN}✓${NC} Backend API: ${DOCKER_USERNAME}/comments-system-backend-api"

# Backend Data
sed -i "s|repository: .*/comments-system-backend-data|repository: ${DOCKER_USERNAME}/comments-system-backend-data|g" "$VALUES_FILE"
echo -e "${GREEN}✓${NC} Backend Data: ${DOCKER_USERNAME}/comments-system-backend-data"

echo ""
echo "========================================"
echo -e "${GREEN}✓ Imágenes actualizadas exitosamente!${NC}"
echo "========================================"
echo ""
echo "Nuevas imágenes configuradas:"
echo "  • ${DOCKER_USERNAME}/comments-system-frontend:latest"
echo "  • ${DOCKER_USERNAME}/comments-system-backend-api:latest"
echo "  • ${DOCKER_USERNAME}/comments-system-backend-data:latest"
echo ""
echo "⚠️  IMPORTANTE: Asegúrate de que estas imágenes existan en Docker Hub"
echo ""
echo "Para verificar:"
echo "  docker pull ${DOCKER_USERNAME}/comments-system-frontend:latest"
echo "  docker pull ${DOCKER_USERNAME}/comments-system-backend-api:latest"
echo "  docker pull ${DOCKER_USERNAME}/comments-system-backend-data:latest"
echo ""
echo "Siguiente paso:"
echo "  git add $VALUES_FILE"
echo "  git commit -m 'Update Docker images to ${DOCKER_USERNAME}'"
echo "  git push"
echo ""
