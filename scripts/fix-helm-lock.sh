#!/bin/bash

###############################################################################
# Script: fix-helm-lock.sh
# Description: Libera un release de Helm bloqueado
# Usage: ./fix-helm-lock.sh <namespace>
###############################################################################

set -e

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
    echo "Error: Namespace requerido"
    echo "Uso: $0 <namespace>"
    echo "Ejemplo: $0 usuario-dev"
    exit 1
fi

echo "================================================"
echo "  Liberando Release de Helm Bloqueado"
echo "================================================"
echo ""
echo "Namespace: $NAMESPACE"
echo "Release: comments-system"
echo ""

# Verificar si el release existe
if helm list -n $NAMESPACE | grep -q comments-system; then
    echo "✓ Release encontrado"
    echo ""

    # Mostrar estado actual
    echo "Estado actual del release:"
    helm list -n $NAMESPACE
    echo ""

    # Obtener información del release
    echo "Historial del release:"
    helm history comments-system -n $NAMESPACE
    echo ""

    # Opciones de resolución
    echo "================================================"
    echo "  Opciones de Resolución"
    echo "================================================"
    echo ""
    echo "1. ROLLBACK a la última versión exitosa:"
    echo "   helm rollback comments-system -n $NAMESPACE"
    echo ""
    echo "2. UNINSTALL completo (perderás datos):"
    echo "   helm uninstall comments-system -n $NAMESPACE"
    echo ""
    echo "3. FORZAR upgrade (peligroso):"
    echo "   helm upgrade comments-system ./helm/comments-system \\"
    echo "     --namespace $NAMESPACE \\"
    echo "     --force \\"
    echo "     --values ./helm/comments-system/values.yaml"
    echo ""

    # Preguntar qué hacer
    read -p "¿Deseas hacer UNINSTALL y empezar de cero? (s/n): " response

    if [ "$response" = "s" ] || [ "$response" = "S" ]; then
        echo ""
        echo "Desinstalando release..."
        helm uninstall comments-system -n $NAMESPACE
        echo ""
        echo "✓ Release desinstalado exitosamente"
        echo ""
        echo "Ahora puedes ejecutar el workflow nuevamente desde GitHub Actions"
    else
        echo ""
        echo "No se realizaron cambios. Ejecuta manualmente la opción que prefieras."
    fi
else
    echo "✗ Release 'comments-system' no encontrado en namespace '$NAMESPACE'"
    echo ""
    echo "Verifica el namespace correcto:"
    echo "  oc project"
    echo "  helm list -A"
fi
