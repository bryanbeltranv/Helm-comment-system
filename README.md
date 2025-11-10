# Comments System - Kubernetes/OpenShift Deployment

![Helm](https://img.shields.io/badge/Helm-v3.13-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.27+-blue)
![OpenShift](https://img.shields.io/badge/OpenShift-4.x-red)

Repositorio centralizado para desplegar el sistema de comentarios completo en OpenShift usando Helm Charts con templates genéricos y reutilizables. 100% declarativo, sin comandos manuales.

## 📋 Tabla de Contenidos

- [Arquitectura](#-arquitectura)
- [Estructura del Repositorio](#-estructura-del-repositorio)
- [Características](#-características)
- [Requisitos Previos](#-requisitos-previos)
- [Configuración](#-configuración)
- [Despliegue](#-despliegue)
- [Gestión de Secrets](#-gestión-de-secrets)
- [Verificación](#-verificación)
- [CI/CD](#-cicd)
- [Troubleshooting](#-troubleshooting)
- [Agregar Nuevo Microservicio](#-agregar-nuevo-microservicio)

## 🏗 Arquitectura

El sistema consta de 4 componentes principales:

```
┌─────────────┐
│   Frontend  │ ← Exposición externa via Route (HTTPS)
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Backend API │ ← API Gateway
└──────┬──────┘
       │
       ↓
┌──────────────┐
│ Backend Data │ ← Capa de acceso a datos
└──────┬───────┘
       │
       ↓
┌──────────────┐
│  PostgreSQL  │ ← Base de datos (con PVC)
└──────────────┘
```

### Comunicación y Seguridad

- **NetworkPolicies** implementadas para seguridad en red
- Comunicación interna: ClusterIP Services
- Exposición externa: Solo Frontend via OpenShift Route con TLS
- **HPA** (Horizontal Pod Autoscaler) configurado para todos los servicios excepto PostgreSQL

## 📁 Estructura del Repositorio

```
comments-system-k8s/
├── helm/
│   └── comments-system/
│       ├── Chart.yaml              # Metadata del chart
│       ├── values.yaml             # Configuración centralizada de TODOS los servicios
│       ├── templates/              # Templates genéricos reutilizables
│       │   ├── _helpers.tpl        # Helper templates
│       │   ├── deployment.yaml     # UN SOLO archivo para TODOS los deployments
│       │   ├── service.yaml        # UN SOLO archivo para TODOS los services
│       │   ├── route.yaml          # UN SOLO archivo para TODOS los routes
│       │   ├── hpa.yaml            # UN SOLO archivo para TODOS los HPAs
│       │   ├── pvc.yaml            # PersistentVolumeClaim para database
│       │   ├── secret.yaml         # Secrets centralizados
│       │   └── networkpolicy.yaml  # Políticas de red
│       └── values/
│           ├── dev.yaml            # Overrides para desarrollo
│           └── prod.yaml           # Overrides para producción
├── .github/
│   └── workflows/
│       └── deploy-openshift.yml    # CI/CD para despliegue automático
├── scripts/
│   └── verify-deployment.sh        # Script de verificación post-deploy
├── README.md
└── SPEC-k8s-deployment.md          # Especificación técnica completa
```

## ✨ Características

- **Templates Genéricos Reutilizables**: Un solo archivo por tipo de recurso que itera sobre `values.yaml`
- **Configuración Centralizada**: Todos los microservicios configurados en `values.yaml`
- **100% Declarativo**: Solo YAML, sin comandos manuales
- **NetworkPolicies**: Seguridad de red implementada (deny all + allow específicos)
- **Secrets Management**: Credenciales en Kubernetes Secrets
- **HPA**: Autoscaling automático basado en CPU y memoria
- **Health Checks**: Liveness y Readiness probes configurados
- **Persistent Storage**: PVC para PostgreSQL
- **CI/CD**: GitHub Actions para despliegue automático
- **Multi-Environment**: Soporte para dev y prod

## 📋 Requisitos Previos

### Local Development

- Helm 3.13+
- kubectl o oc CLI
- Acceso a OpenShift Sandbox o cluster Kubernetes

### OpenShift Sandbox

1. Regístrate en [Red Hat OpenShift Sandbox](https://developers.redhat.com/developer-sandbox)
2. Obtén tu token de autenticación:
   ```bash
   oc login --token=<YOUR-TOKEN> --server=<OPENSHIFT-SERVER>
   ```
3. Identifica tu namespace asignado:
   ```bash
   oc project
   ```

## ⚙️ Configuración

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd Helm-comment-system
```

### 2. Configurar Secrets de GitHub

En tu repositorio de GitHub, ve a **Settings → Secrets and variables → Actions** y agrega:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `OPENSHIFT_TOKEN` | Token de autenticación de OpenShift | `sha256~xxxxx...` |
| `OPENSHIFT_SERVER` | URL del servidor OpenShift | `https://api.sandbox.openshift.com:6443` |
| `OPENSHIFT_NAMESPACE` | Namespace asignado por OpenShift | `usuario-dev` |
| `OPENSHIFT_DOMAIN` | Dominio de OpenShift | `apps.sandbox.openshiftapps.com` |

### 3. Personalizar Valores (Opcional)

Edita `helm/comments-system/values.yaml` para ajustar:

- Imágenes de Docker Hub
- Recursos (CPU/Memoria)
- Réplicas
- Variables de entorno
- Secrets de base de datos

## 🚀 Despliegue

### Despliegue Manual Local

#### 1. Validar el Chart

```bash
# Lint del chart
helm lint ./helm/comments-system

# Dry-run (ver los manifiestos generados sin aplicarlos)
helm template comments-system ./helm/comments-system \
  --namespace <YOUR-NAMESPACE> \
  --set global.namespace=<YOUR-NAMESPACE> \
  --set global.domain=<YOUR-DOMAIN> \
  --debug
```

#### 2. Instalar el Chart

**Para Desarrollo:**
```bash
helm install comments-system ./helm/comments-system \
  --namespace <YOUR-NAMESPACE> \
  --create-namespace \
  --set global.namespace=<YOUR-NAMESPACE> \
  --set global.domain=<YOUR-DOMAIN> \
  --values ./helm/comments-system/values/dev.yaml \
  --wait \
  --timeout 10m
```

**Para Producción:**
```bash
helm install comments-system ./helm/comments-system \
  --namespace <YOUR-NAMESPACE> \
  --create-namespace \
  --set global.namespace=<YOUR-NAMESPACE> \
  --set global.domain=<YOUR-DOMAIN> \
  --values ./helm/comments-system/values/prod.yaml \
  --wait \
  --timeout 10m
```

#### 3. Actualizar el Despliegue

```bash
helm upgrade comments-system ./helm/comments-system \
  --namespace <YOUR-NAMESPACE> \
  --set global.namespace=<YOUR-NAMESPACE> \
  --set global.domain=<YOUR-DOMAIN> \
  --values ./helm/comments-system/values.yaml \
  --wait
```

#### 4. Desinstalar

```bash
helm uninstall comments-system --namespace <YOUR-NAMESPACE>
```

### Despliegue Automático (GitHub Actions)

El workflow de GitHub Actions se ejecuta automáticamente cuando:

1. **Push a `main`**: Con cambios en `helm/**` o `.github/workflows/`
2. **Workflow manual**: Via GitHub UI seleccionando el environment (dev/prod)

Para ejecutar manualmente:
1. Ve a **Actions** en GitHub
2. Selecciona **Deploy to OpenShift**
3. Click en **Run workflow**
4. Selecciona el environment (dev/prod)
5. Click en **Run workflow**

## 🔐 Gestión de Secrets

### Secrets de PostgreSQL

Los secrets están codificados en Base64 en `values.yaml`:

```yaml
secrets:
  postgres:
    name: postgres-secret
    data:
      database: Y29tbWVudHNfZGI=      # Base64: comments_db
      username: cG9zdGdyZXM=          # Base64: postgres
      password: cG9zdGdyZXNAMTIzNDU=  # Base64: postgres@12345
```

**⚠️ IMPORTANTE**: Para producción, cambia estas credenciales:

```bash
# Generar nuevos valores en Base64
echo -n "mi_base_datos" | base64
echo -n "mi_usuario" | base64
echo -n "mi_password_seguro" | base64
```

Luego actualiza `values.yaml` o usa `--set` en el comando de Helm:

```bash
helm install comments-system ./helm/comments-system \
  --set secrets.postgres.data.password=$(echo -n "new_password" | base64)
```

## ✅ Verificación

### Usando el Script de Verificación

```bash
# Dar permisos de ejecución
chmod +x ./scripts/verify-deployment.sh

# Ejecutar verificación
./scripts/verify-deployment.sh <YOUR-NAMESPACE>
```

El script verifica:
- ✓ Namespace existe
- ✓ Deployments están listos
- ✓ Services existen
- ✓ PVCs están bound
- ✓ Secrets existen
- ✓ Routes están configurados
- ✓ NetworkPolicies aplicados
- ✓ HPAs funcionando
- ✓ Pods en estado Running
- ✓ Conectividad entre servicios

### Verificación Manual

```bash
# Ver todos los recursos
kubectl get all -n <NAMESPACE>

# Ver deployments
kubectl get deployments -n <NAMESPACE>

# Ver pods
kubectl get pods -n <NAMESPACE>

# Ver services
kubectl get services -n <NAMESPACE>

# Ver routes (OpenShift)
oc get routes -n <NAMESPACE>

# Ver PVCs
kubectl get pvc -n <NAMESPACE>

# Ver NetworkPolicies
kubectl get networkpolicies -n <NAMESPACE>

# Ver HPAs
kubectl get hpa -n <NAMESPACE>

# Ver logs de un pod
kubectl logs -f deployment/frontend -n <NAMESPACE>

# Describir un recurso
kubectl describe deployment backend-api -n <NAMESPACE>
```

### Probar Conectividad

```bash
# Frontend → Backend API
kubectl exec -it deployment/frontend -n <NAMESPACE> -- wget -O- http://backend-api:3000/health

# Backend API → Backend Data
kubectl exec -it deployment/backend-api -n <NAMESPACE> -- wget -O- http://backend-data:3001/health

# Backend Data → PostgreSQL
kubectl exec -it deployment/backend-data -n <NAMESPACE> -- pg_isready -h postgres -p 5432
```

## 🔄 CI/CD

### GitHub Actions Workflow

El workflow `deploy-openshift.yml` realiza:

1. **Checkout** del código
2. **Instalación** de Helm y OpenShift CLI
3. **Login** a OpenShift
4. **Lint** del Helm chart
5. **Dry-run** para validar templates
6. **Deploy** con Helm
7. **Verificación** de recursos
8. **Wait** para pods ready
9. **Obtener Routes** desplegados
10. **Ejecutar** script de verificación
11. **Summary** del despliegue

### Logs del Workflow

Los logs están disponibles en **Actions → Deploy to OpenShift → [workflow run]**

## 🔧 Troubleshooting

### Pods no arrancan

```bash
# Ver estado de los pods
kubectl get pods -n <NAMESPACE>

# Ver logs del pod
kubectl logs <POD-NAME> -n <NAMESPACE>

# Describir el pod para ver eventos
kubectl describe pod <POD-NAME> -n <NAMESPACE>
```

### Problemas con PVC

```bash
# Ver estado del PVC
kubectl get pvc -n <NAMESPACE>

# Describir PVC
kubectl describe pvc postgres-pvc -n <NAMESPACE>

# Ver eventos
kubectl get events -n <NAMESPACE> --sort-by='.lastTimestamp'
```

### NetworkPolicy bloquea conexiones

```bash
# Ver NetworkPolicies
kubectl get networkpolicies -n <NAMESPACE>

# Describir una NetworkPolicy específica
kubectl describe networkpolicy allow-frontend-to-backend-api -n <NAMESPACE>

# Probar conectividad desde un pod
kubectl exec -it deployment/frontend -n <NAMESPACE> -- wget -O- http://backend-api:3000/health
```

### Problemas con Secrets

```bash
# Ver secrets
kubectl get secrets -n <NAMESPACE>

# Ver contenido del secret (Base64 encoded)
kubectl get secret postgres-secret -n <NAMESPACE> -o yaml

# Decodificar un valor
kubectl get secret postgres-secret -n <NAMESPACE> -o jsonpath='{.data.password}' | base64 -d
```

### Ver Eventos Recientes

```bash
kubectl get events -n <NAMESPACE> --sort-by='.lastTimestamp' | tail -20
```

## ➕ Agregar Nuevo Microservicio

Para agregar un nuevo microservicio, solo edita `values.yaml`:

```yaml
microservices:
  - name: nuevo-servicio
    enabled: true
    image:
      repository: usuario/nuevo-servicio
      tag: latest
      pullPolicy: Always

    replicas: 2
    port: 8080
    targetPort: 8080

    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"

    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10

    readinessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5

    env:
      - name: PORT
        value: "8080"

    route:
      enabled: false  # true si necesita exposición externa

    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPUUtilizationPercentage: 70
      targetMemoryUtilizationPercentage: 80

    labels:
      app: comments-system
      component: nuevo-servicio
      tier: application
```

**NO es necesario crear nuevos templates**, el chart reutilizará los existentes automáticamente.

## 📚 Documentación Adicional

- [Especificación Técnica Completa](SPEC-k8s-deployment.md)
- [Helm Documentation](https://helm.sh/docs/)
- [OpenShift Routes](https://docs.openshift.com/container-platform/latest/networking/routes/route-configuration.html)
- [Kubernetes NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Add nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo la licencia MIT.

## 👥 Autores

- Comments System Team

## 📧 Soporte

Para soporte y preguntas, abre un Issue en GitHub.

---

**Última actualización**: 2025-01-10
