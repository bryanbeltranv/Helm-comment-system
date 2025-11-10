#!/bin/bash

###############################################################################
# Script: verify-deployment.sh
# Description: Verifies the deployment of the Comments System on OpenShift
# Usage: ./verify-deployment.sh <namespace>
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE=${1:-default}

echo "================================================"
echo "  Comments System - Deployment Verification"
echo "  Namespace: $NAMESPACE"
echo "================================================"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if namespace exists
echo "1. Checking namespace..."
if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_status 0 "Namespace '$NAMESPACE' exists"
else
    print_status 1 "Namespace '$NAMESPACE' does not exist"
    exit 1
fi
echo ""

# Check deployments
echo "2. Checking deployments..."
DEPLOYMENTS=("frontend" "backend-api" "backend-data" "postgres")
ALL_DEPLOYMENTS_OK=true

for deployment in "${DEPLOYMENTS[@]}"; do
    if kubectl get deployment $deployment -n $NAMESPACE &> /dev/null; then
        REPLICAS=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
        DESIRED=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.spec.replicas}')

        if [ "$REPLICAS" == "$DESIRED" ] && [ "$REPLICAS" != "" ]; then
            print_status 0 "Deployment '$deployment' is ready ($REPLICAS/$DESIRED replicas)"
        else
            print_status 1 "Deployment '$deployment' is not ready ($REPLICAS/$DESIRED replicas)"
            ALL_DEPLOYMENTS_OK=false
        fi
    else
        print_status 1 "Deployment '$deployment' not found"
        ALL_DEPLOYMENTS_OK=false
    fi
done
echo ""

# Check services
echo "3. Checking services..."
SERVICES=("frontend" "backend-api" "backend-data" "postgres")
ALL_SERVICES_OK=true

for service in "${SERVICES[@]}"; do
    if kubectl get service $service -n $NAMESPACE &> /dev/null; then
        print_status 0 "Service '$service' exists"
    else
        print_status 1 "Service '$service' not found"
        ALL_SERVICES_OK=false
    fi
done
echo ""

# Check PVC
echo "4. Checking Persistent Volume Claims..."
if kubectl get pvc postgres-pvc -n $NAMESPACE &> /dev/null; then
    PVC_STATUS=$(kubectl get pvc postgres-pvc -n $NAMESPACE -o jsonpath='{.status.phase}')
    if [ "$PVC_STATUS" == "Bound" ]; then
        print_status 0 "PVC 'postgres-pvc' is Bound"
    else
        print_status 1 "PVC 'postgres-pvc' is not Bound (Status: $PVC_STATUS)"
    fi
else
    print_status 1 "PVC 'postgres-pvc' not found"
fi
echo ""

# Check secrets
echo "5. Checking secrets..."
if kubectl get secret postgres-secret -n $NAMESPACE &> /dev/null; then
    print_status 0 "Secret 'postgres-secret' exists"
else
    print_status 1 "Secret 'postgres-secret' not found"
fi
echo ""

# Check routes
echo "6. Checking routes..."
if command -v oc &> /dev/null; then
    if oc get route frontend -n $NAMESPACE &> /dev/null; then
        ROUTE_HOST=$(oc get route frontend -n $NAMESPACE -o jsonpath='{.spec.host}')
        print_status 0 "Route 'frontend' exists (Host: $ROUTE_HOST)"
    else
        print_status 1 "Route 'frontend' not found"
    fi
else
    print_warning "OpenShift CLI (oc) not found, skipping route check"
fi
echo ""

# Check NetworkPolicies
echo "7. Checking Network Policies..."
NETWORK_POLICIES=$(kubectl get networkpolicies -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ $NETWORK_POLICIES -gt 0 ]; then
    print_status 0 "Found $NETWORK_POLICIES Network Policies"
    kubectl get networkpolicies -n $NAMESPACE --no-headers | awk '{print "   - " $1}'
else
    print_warning "No Network Policies found"
fi
echo ""

# Check HPAs
echo "8. Checking Horizontal Pod Autoscalers..."
HPAS=$(kubectl get hpa -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ $HPAS -gt 0 ]; then
    print_status 0 "Found $HPAS HPAs"
    kubectl get hpa -n $NAMESPACE --no-headers | awk '{print "   - " $1}'
else
    print_warning "No HPAs found"
fi
echo ""

# Check pod health
echo "9. Checking pod health..."
ALL_PODS_OK=true
PODS=$(kubectl get pods -n $NAMESPACE -l app=comments-system --no-headers 2>/dev/null)

if [ -z "$PODS" ]; then
    print_status 1 "No pods found with label app=comments-system"
    ALL_PODS_OK=false
else
    while IFS= read -r line; do
        POD_NAME=$(echo $line | awk '{print $1}')
        POD_STATUS=$(echo $line | awk '{print $3}')
        POD_READY=$(echo $line | awk '{print $2}')

        if [ "$POD_STATUS" == "Running" ]; then
            print_status 0 "Pod '$POD_NAME' is Running ($POD_READY)"
        else
            print_status 1 "Pod '$POD_NAME' is not Running (Status: $POD_STATUS, Ready: $POD_READY)"
            ALL_PODS_OK=false
        fi
    done <<< "$PODS"
fi
echo ""

# Test connectivity (if possible)
echo "10. Testing connectivity..."
FRONTEND_POD=$(kubectl get pod -n $NAMESPACE -l component=frontend --no-headers 2>/dev/null | head -1 | awk '{print $1}')

if [ ! -z "$FRONTEND_POD" ]; then
    echo "Testing frontend -> backend-api connection..."
    if kubectl exec -n $NAMESPACE $FRONTEND_POD -- wget -q -O- --timeout=5 http://backend-api:3000/health &> /dev/null; then
        print_status 0 "Frontend can reach backend-api"
    else
        print_warning "Frontend cannot reach backend-api (this may be expected if health endpoint doesn't exist yet)"
    fi
else
    print_warning "No frontend pod found for connectivity test"
fi
echo ""

# Final summary
echo "================================================"
echo "  Verification Summary"
echo "================================================"

if $ALL_DEPLOYMENTS_OK && $ALL_SERVICES_OK && $ALL_PODS_OK; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""

    if command -v oc &> /dev/null; then
        FRONTEND_URL=$(oc get route frontend -n $NAMESPACE -o jsonpath='{.spec.host}' 2>/dev/null)
        if [ ! -z "$FRONTEND_URL" ]; then
            echo "🌐 Access your application at: https://$FRONTEND_URL"
        fi
    fi

    exit 0
else
    echo -e "${RED}✗ Some checks failed!${NC}"
    echo ""
    echo "Run the following commands for more details:"
    echo "  kubectl get all -n $NAMESPACE"
    echo "  kubectl describe pods -n $NAMESPACE"
    echo "  kubectl logs -n $NAMESPACE -l app=comments-system --tail=50"
    exit 1
fi
