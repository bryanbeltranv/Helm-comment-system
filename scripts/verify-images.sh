#!/bin/bash

###############################################################################
# Script: verify-images.sh
# Description: Verifica que las imágenes Docker existan y sean accesibles
# Usage: ./verify-images.sh
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Verificación de Imágenes Docker"
echo "================================================"
echo ""

# Imágenes a verificar
IMAGES=(
    "bryanbeltranv/frontend:latest"
    "bryanbeltranv/backend-api:tagname"
    "bryanbeltranv/backend-data:latest"
    "postgres:15-alpine"
)

ALL_OK=true

for image in "${IMAGES[@]}"; do
    echo -n "Verificando: $image ... "

    if docker pull $image > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo -e "  ${YELLOW}⚠${NC} La imagen no existe o no es accesible"
        ALL_OK=false
    fi
done

echo ""
echo "================================================"

if $ALL_OK; then
    echo -e "${GREEN}✓ Todas las imágenes están disponibles!${NC}"
    echo ""
    echo "Puedes proceder con el despliegue:"
    echo "  1. Configura los secrets en GitHub"
    echo "  2. Ejecuta el workflow desde GitHub Actions"
    exit 0
else
    echo -e "${RED}✗ Algunas imágenes no están disponibles${NC}"
    echo ""
    echo "Soluciones posibles:"
    echo "  1. Verifica que las imágenes existan en Docker Hub:"
    echo "     https://hub.docker.com/u/bryanbeltranv"
    echo ""
    echo "  2. Si las imágenes son privadas, necesitas:"
    echo "     - Hacer docker login"
    echo "     - Configurar ImagePullSecret en OpenShift"
    echo ""
    echo "  3. Si las imágenes no existen, créalas:"
    echo "     docker build -t bryanbeltranv/frontend:latest ."
    echo "     docker push bryanbeltranv/frontend:latest"
    exit 1
fi
