# Especificación: comments-system-k8s

## Objetivo
Repositorio centralizado de despliegue que contiene los Helm charts con templates genéricos y reutilizables para desplegar el sistema completo en OpenShift Sandbox. Todo debe ser 100% declarativo (YAML) sin comandos manuales de `oc`.

## Arquitectura del Repositorio

```
comments-system-k8s/
├── helm/
│   └── comments-system/
│       ├── Chart.yaml
│       ├── values.yaml              # Configuración centralizada de TODOS los servicios
│       ├── templates/
│       │   ├── _helpers.tpl         # Helper templates
│       │   ├── namespace.yaml       # Namespace (si aplica)
│       │   ├── deployment.yaml      # ⚠️ UN SOLO archivo para TODOS los deployments
│       │   ├── service.yaml         # ⚠️ UN SOLO archivo para TODOS los services
│       │   ├── route.yaml           # ⚠️ UN SOLO archivo para TODOS los routes
│       │   ├── hpa.yaml             # ⚠️ UN SOLO archivo para TODOS los HPAs
│       │   ├── configmap.yaml       # ConfigMaps centralizados
│       │   ├── secret.yaml          # Secrets centralizados
│       │   ├── pvc.yaml             # PersistentVolumeClaim para database
│       │   └── networkpolicy.yaml   # Políticas de red
│       └── values/
│           ├── dev.yaml             # Overrides para desarrollo
│           └── prod.yaml            # Overrides para producción
├── .github/
│   └── workflows/
│       └── deploy-openshift.yml     # CI/CD para despliegue
├── scripts/
│   └── verify-deployment.sh         # Script de verificación post-deploy
├── README.md
└── SPEC-k8s-deployment.md           # Este archivo
```

## Principio Clave: Templates Genéricos Reutilizables

🎯 **IMPORTANTE**: Según especificación del profesor, NO debe haber un archivo por microservicio (frontend-deployment.yaml, backend-api-deployment.yaml, etc.), sino UN SOLO archivo genérico que itere sobre `values.yaml`.

### Ejemplo de Estructura INCORRECTA ❌:
```
templates/
├── frontend-deployment.yaml
├── frontend-service.yaml
├── backend-api-deployment.yaml
├── backend-api-service.yaml
├── backend-data-deployment.yaml
└── backend-data-service.yaml
```

### Estructura CORRECTA ✅:
```
templates/
├── deployment.yaml      # Itera sobre microservices en values.yaml
├── service.yaml         # Itera sobre microservices en values.yaml
├── route.yaml           # Itera sobre microservices en values.yaml
└── hpa.yaml             # Itera sobre microservices en values.yaml
```

## values.yaml - Configuración Centralizada

Este archivo define TODOS los microservicios y sus configuraciones:

```yaml
# Configuración global
global:
  namespace: <tu-namespace-openshift>  # Namespace asignado por OpenShift Sandbox
  domain: <tu-dominio-openshift>       # Dominio de OpenShift Sandbox
  registry: docker.io                   # Docker Hub
  registryUser: <tu-usuario-dockerhub>

# Lista de microservicios
microservices:
  - name: frontend
    enabled: true
    image:
      repository: bryanbeltranv/comments-system-frontend
      tag: latest
      pullPolicy: Always
    
    replicas: 2
    
    port: 80
    targetPort: 80
    
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
    
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
    
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
    
    env:
      - name: BACKEND_API_URL
        value: "http://backend-api:3000"
    
    # Configuración para Route (solo frontend necesita exposición externa)
    route:
      enabled: true
      host: ""  # OpenShift asignará automáticamente
      tls:
        enabled: true
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
    
    # HPA
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPUUtilizationPercentage: 70
      targetMemoryUtilizationPercentage: 80
    
    # Labels para NetworkPolicies
    labels:
      app: comments-system
      component: frontend
      tier: presentation

  - name: backend-api
    enabled: true
    image:
      repository: bryanbeltranv/comments-system-backend-api
      tag: latest
      pullPolicy: Always
    
    replicas: 2
    
    port: 3000
    targetPort: 3000
    
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "400m"
    
    livenessProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 30
      periodSeconds: 10
    
    readinessProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 15
      periodSeconds: 5
    
    env:
      - name: PORT
        value: "3000"
      - name: BACKEND_DATA_URL
        value: "http://backend-data:3001"
      - name: NODE_ENV
        value: "production"
    
    route:
      enabled: false  # No expuesto externamente
    
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 8
      targetCPUUtilizationPercentage: 70
      targetMemoryUtilizationPercentage: 80
    
    labels:
      app: comments-system
      component: backend-api
      tier: application

  - name: backend-data
    enabled: true
    image:
      repository: bryanbeltranv/comments-system-backend-data
      tag: latest
      pullPolicy: Always
    
    replicas: 2
    
    port: 3001
    targetPort: 3001
    
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "400m"
    
    livenessProbe:
      httpGet:
        path: /health
        port: 3001
      initialDelaySeconds: 45
      periodSeconds: 10
      failureThreshold: 5
    
    readinessProbe:
      httpGet:
        path: /health
        port: 3001
      initialDelaySeconds: 30
      periodSeconds: 5
      failureThreshold: 3
    
    env:
      - name: PORT
        value: "3001"
      - name: DB_HOST
        value: "postgres-service"
      - name: DB_PORT
        value: "5432"
      - name: DB_NAME
        valueFrom:
          secretKeyRef:
            name: postgres-secret
            key: database
      - name: DB_USER
        valueFrom:
          secretKeyRef:
            name: postgres-secret
            key: username
      - name: DB_PASSWORD
        valueFrom:
          secretKeyRef:
            name: postgres-secret
            key: password
      - name: NODE_ENV
        value: "production"
    
    route:
      enabled: false
    
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 6
      targetCPUUtilizationPercentage: 75
      targetMemoryUtilizationPercentage: 85
    
    labels:
      app: comments-system
      component: backend-data
      tier: data-access

  - name: postgres
    enabled: true
    image:
      repository: postgres
      tag: "15-alpine"
      pullPolicy: IfNotPresent
    
    replicas: 1  # Database no debe escalar horizontalmente
    
    port: 5432
    targetPort: 5432
    
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"
    
    livenessProbe:
      exec:
        command:
          - pg_isready
          - -U
          - postgres
      initialDelaySeconds: 30
      periodSeconds: 10
    
    readinessProbe:
      exec:
        command:
          - pg_isready
          - -U
          - postgres
      initialDelaySeconds: 10
      periodSeconds: 5
    
    env:
      - name: POSTGRES_DB
        valueFrom:
          secretKeyRef:
            name: postgres-secret
            key: database
      - name: POSTGRES_USER
        valueFrom:
          secretKeyRef:
            name: postgres-secret
            key: username
      - name: POSTGRES_PASSWORD
        valueFrom:
          secretKeyRef:
            name: postgres-secret
            key: password
      - name: PGDATA
        value: /var/lib/postgresql/data/pgdata
    
    # Almacenamiento persistente
    persistence:
      enabled: true
      storageClass: ""  # OpenShift asignará el default
      accessMode: ReadWriteOnce
      size: 5Gi
      mountPath: /var/lib/postgresql/data
    
    route:
      enabled: false
    
    autoscaling:
      enabled: false  # Database no debe autoescalar
    
    labels:
      app: comments-system
      component: postgres
      tier: database

# Secrets
secrets:
  postgres:
    name: postgres-secret
    data:
      database: Y29tbWVudHNfZGI=      # Base64: comments_db
      username: cG9zdGdyZXM=          # Base64: postgres
      password: cG9zdGdyZXNAMTIzNDU=  # Base64: postgres@12345

# ConfigMaps (si se necesitan)
configmaps: []

# NetworkPolicies
networkPolicies:
  enabled: true
  
  # Default Deny All
  denyAll:
    enabled: true
  
  # Reglas específicas
  rules:
    - name: allow-frontend-to-backend-api
      podSelector:
        component: backend-api
      ingress:
        - from:
            - podSelector:
                component: frontend
          ports:
            - protocol: TCP
              port: 3000
    
    - name: allow-backend-api-to-backend-data
      podSelector:
        component: backend-data
      ingress:
        - from:
            - podSelector:
                component: backend-api
          ports:
            - protocol: TCP
              port: 3001
    
    - name: allow-backend-data-to-postgres
      podSelector:
        component: postgres
      ingress:
        - from:
            - podSelector:
                component: backend-data
          ports:
            - protocol: TCP
              port: 5432
    
    - name: allow-ingress-to-frontend
      podSelector:
        component: frontend
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  network.openshift.io/policy-group: ingress
          ports:
            - protocol: TCP
              port: 80
```

## Templates Genéricos

### templates/deployment.yaml

```yaml
{{- range $service := .Values.microservices }}
{{- if $service.enabled }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $service.name }}
  namespace: {{ $.Values.global.namespace }}
  labels:
    {{- range $key, $value := $service.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
spec:
  replicas: {{ $service.replicas }}
  selector:
    matchLabels:
      {{- range $key, $value := $service.labels }}
      {{ $key }}: {{ $value }}
      {{- end }}
  template:
    metadata:
      labels:
        {{- range $key, $value := $service.labels }}
        {{ $key }}: {{ $value }}
        {{- end }}
    spec:
      {{- if $service.persistence }}
      {{- if $service.persistence.enabled }}
      volumes:
        - name: {{ $service.name }}-storage
          persistentVolumeClaim:
            claimName: {{ $service.name }}-pvc
      {{- end }}
      {{- end }}
      containers:
        - name: {{ $service.name }}
          image: "{{ $service.image.repository }}:{{ $service.image.tag }}"
          imagePullPolicy: {{ $service.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ $service.targetPort }}
              protocol: TCP
          {{- if $service.env }}
          env:
            {{- range $service.env }}
            - name: {{ .name }}
              {{- if .value }}
              value: {{ .value | quote }}
              {{- else if .valueFrom }}
              valueFrom:
                {{- toYaml .valueFrom | nindent 16 }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if $service.livenessProbe }}
          livenessProbe:
            {{- toYaml $service.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if $service.readinessProbe }}
          readinessProbe:
            {{- toYaml $service.readinessProbe | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml $service.resources | nindent 12 }}
          {{- if $service.persistence }}
          {{- if $service.persistence.enabled }}
          volumeMounts:
            - name: {{ $service.name }}-storage
              mountPath: {{ $service.persistence.mountPath }}
          {{- end }}
          {{- end }}
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
            seccompProfile:
              type: RuntimeDefault
{{- end }}
{{- end }}
```

### templates/service.yaml

```yaml
{{- range $service := .Values.microservices }}
{{- if $service.enabled }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $service.name }}
  namespace: {{ $.Values.global.namespace }}
  labels:
    {{- range $key, $value := $service.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
spec:
  type: ClusterIP
  ports:
    - port: {{ $service.port }}
      targetPort: {{ $service.targetPort }}
      protocol: TCP
      name: http
  selector:
    {{- range $key, $value := $service.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
{{- end }}
{{- end }}
```

### templates/route.yaml

```yaml
{{- range $service := .Values.microservices }}
{{- if and $service.enabled $service.route.enabled }}
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: {{ $service.name }}
  namespace: {{ $.Values.global.namespace }}
  labels:
    {{- range $key, $value := $service.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
spec:
  {{- if $service.route.host }}
  host: {{ $service.route.host }}
  {{- end }}
  to:
    kind: Service
    name: {{ $service.name }}
    weight: 100
  port:
    targetPort: http
  {{- if $service.route.tls }}
  {{- if $service.route.tls.enabled }}
  tls:
    termination: {{ $service.route.tls.termination }}
    insecureEdgeTerminationPolicy: {{ $service.route.tls.insecureEdgeTerminationPolicy }}
  {{- end }}
  {{- end }}
  wildcardPolicy: None
{{- end }}
{{- end }}
```

### templates/hpa.yaml

```yaml
{{- range $service := .Values.microservices }}
{{- if and $service.enabled $service.autoscaling.enabled }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $service.name }}-hpa
  namespace: {{ $.Values.global.namespace }}
  labels:
    {{- range $key, $value := $service.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $service.name }}
  minReplicas: {{ $service.autoscaling.minReplicas }}
  maxReplicas: {{ $service.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $service.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $service.autoscaling.targetMemoryUtilizationPercentage }}
{{- end }}
{{- end }}
```

### templates/pvc.yaml

```yaml
{{- range $service := .Values.microservices }}
{{- if and $service.enabled $service.persistence }}
{{- if $service.persistence.enabled }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $service.name }}-pvc
  namespace: {{ $.Values.global.namespace }}
  labels:
    {{- range $key, $value := $service.labels }}
    {{ $key }}: {{ $value }}
    {{- end }}
spec:
  accessModes:
    - {{ $service.persistence.accessMode }}
  resources:
    requests:
      storage: {{ $service.persistence.size }}
  {{- if $service.persistence.storageClass }}
  storageClassName: {{ $service.persistence.storageClass }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
```

### templates/secret.yaml

```yaml
{{- if .Values.secrets.postgres }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Values.secrets.postgres.name }}
  namespace: {{ .Values.global.namespace }}
type: Opaque
data:
  {{- range $key, $value := .Values.secrets.postgres.data }}
  {{ $key }}: {{ $value }}
  {{- end }}
{{- end }}
```

### templates/networkpolicy.yaml

```yaml
{{- if .Values.networkPolicies.enabled }}

{{- if .Values.networkPolicies.denyAll.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: {{ .Values.global.namespace }}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
{{- end }}

{{- range $rule := .Values.networkPolicies.rules }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $rule.name }}
  namespace: {{ $.Values.global.namespace }}
spec:
  podSelector:
    matchLabels:
      {{- range $key, $value := $rule.podSelector }}
      {{ $key }}: {{ $value }}
      {{- end }}
  policyTypes:
    - Ingress
  ingress:
    {{- range $rule.ingress }}
    - from:
        {{- range .from }}
        - podSelector:
            matchLabels:
              {{- range $key, $value := .podSelector }}
              {{ $key }}: {{ $value }}
              {{- end }}
        {{- if .namespaceSelector }}
        - namespaceSelector:
            matchLabels:
              {{- range $key, $value := .namespaceSelector.matchLabels }}
              {{ $key }}: {{ $value }}
              {{- end }}
        {{- end }}
        {{- end }}
      {{- if .ports }}
      ports:
        {{- range .ports }}
        - protocol: {{ .protocol }}
          port: {{ .port }}
        {{- end }}
      {{- end }}
    {{- end }}
{{- end }}

{{- end }}
```

## GitHub Actions Workflow

**Archivo**: `.github/workflows/deploy-openshift.yml`

```yaml
name: Deploy to OpenShift

on:
  push:
    branches: [ main ]
    paths:
      - 'helm/**'
      - '.github/workflows/deploy-openshift.yml'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - prod

env:
  HELM_CHART_PATH: ./helm/comments-system
  OPENSHIFT_NAMESPACE: <tu-namespace>

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install OpenShift CLI
        run: |
          curl -sLO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
          tar -xzf openshift-client-linux.tar.gz
          sudo mv oc kubectl /usr/local/bin/
          oc version

      - name: Install Helm
        uses: azure/setup-helm@v3
        with:
          version: 'v3.12.0'

      - name: Login to OpenShift
        run: |
          oc login --token=${{ secrets.OPENSHIFT_TOKEN }} --server=${{ secrets.OPENSHIFT_SERVER }}

      - name: Set target namespace
        run: |
          oc project ${{ env.OPENSHIFT_NAMESPACE }}

      - name: Lint Helm chart
        run: |
          helm lint ${{ env.HELM_CHART_PATH }}

      - name: Deploy with Helm
        run: |
          helm upgrade --install comments-system ${{ env.HELM_CHART_PATH }} \
            --namespace ${{ env.OPENSHIFT_NAMESPACE }} \
            --create-namespace \
            --values ${{ env.HELM_CHART_PATH }}/values.yaml \
            --timeout 10m \
            --wait \
            --debug

      - name: Verify deployment
        run: |
          kubectl get all -n ${{ env.OPENSHIFT_NAMESPACE }}
          kubectl get pvc -n ${{ env.OPENSHIFT_NAMESPACE }}
          kubectl get networkpolicies -n ${{ env.OPENSHIFT_NAMESPACE }}

      - name: Wait for pods to be ready
        run: |
          kubectl wait --for=condition=ready pod \
            -l app=comments-system \
            -n ${{ env.OPENSHIFT_NAMESPACE }} \
            --timeout=300s

      - name: Get Routes
        run: |
          echo "### Deployed Routes ###"
          oc get routes -n ${{ env.OPENSHIFT_NAMESPACE }}
```

## Secrets de GitHub Requeridos

En el repositorio de GitHub, configurar:
- `OPENSHIFT_TOKEN` - Token de autenticación de OpenShift Sandbox
- `OPENSHIFT_SERVER` - URL del servidor OpenShift (ej: https://api.sandbox.openshift.com:6443)

## Orden de Despliegue

Helm desplegará automáticamente en este orden:
1. **Namespace** (si se crea)
2. **Secrets** (postgres-secret)
3. **ConfigMaps** (si existen)
4. **PersistentVolumeClaims** (para database)
5. **Deployments** (todos los microservicios)
6. **Services** (todos los servicios)
7. **Routes** (solo frontend)
8. **HPAs** (autoscaling)
9. **NetworkPolicies** (seguridad de red)

## Agregar Nuevo Microservicio

Para agregar un nuevo microservicio, solo editar `values.yaml`:

```yaml
microservices:
  - name: nuevo-servicio
    enabled: true
    image:
      repository: usuario/nuevo-servicio
      tag: latest
    replicas: 2
    port: 8080
    # ... resto de configuración
```

**NO es necesario crear nuevos templates**, el chart reutilizará los existentes.

## Testing Local con Minikube

```bash
# Instalar chart
helm install comments-system ./helm/comments-system \
  --values ./helm/comments-system/values.yaml \
  --dry-run --debug

# Deploy real
helm install comments-system ./helm/comments-system

# Upgrade
helm upgrade comments-system ./helm/comments-system

# Rollback
helm rollback comments-system

# Uninstall
helm uninstall comments-system
```

## Consideraciones OpenShift Sandbox

1. **Namespace pre-asignado**: No puedes crear namespaces, usa el que te asigna OpenShift
2. **Limites de recursos**: Sandbox tiene quotas limitados
3. **No LoadBalancer**: Usa Routes en lugar de LoadBalancer
4. **SecurityContextConstraints**: OpenShift es más restrictivo, usar `runAsNonRoot: true`
5. **Registry**: Usar Docker Hub o Quay.io

## Troubleshooting

```bash
# Ver logs de un pod
oc logs -f deployment/frontend -n <namespace>

# Describir recursos
oc describe deployment backend-api -n <namespace>
oc describe networkpolicy allow-frontend-to-backend-api -n <namespace>

# Verificar conectividad
oc exec -it deployment/frontend -n <namespace> -- wget -O- http://backend-api:3000/health

# Ver eventos
oc get events -n <namespace> --sort-by='.lastTimestamp'
```

## Validación de NetworkPolicies

```bash
# Desde frontend debe llegar a backend-api
oc exec -it deployment/frontend -- wget -O- http://backend-api:3000/health

# Desde backend-api debe llegar a backend-data
oc exec -it deployment/backend-api -- wget -O- http://backend-data:3001/health

# Desde backend-data debe llegar a postgres
oc exec -it deployment/backend-data -- pg_isready -h postgres-service -p 5432
```

## Notas Importantes

1. ✅ **Templates reutilizables**: Un solo archivo por tipo de recurso
2. ✅ **Configuración centralizada**: Todo en `values.yaml`
3. ✅ **100% Declarativo**: Solo YAML, sin comandos manuales
4. ✅ **NetworkPolicies**: Seguridad de red implementada
5. ✅ **Secrets**: Credenciales en Secrets, no hardcodeadas
6. ✅ **HPA**: Autoscaling configurado
7. ✅ **Health checks**: Probes configurados
8. ✅ **Persistent storage**: PVC para base de datos

---

**Autor**: Sistema de Comentarios OpenShift  
**Última actualización**: 2025-01-10
