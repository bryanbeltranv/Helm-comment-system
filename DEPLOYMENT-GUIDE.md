# Guía Completa de Despliegue con GitHub Actions

## 🎯 Prerequisitos

- [ ] Cuenta de OpenShift Sandbox activa
- [ ] Acceso al repositorio en GitHub
- [ ] Secrets configurados en GitHub (ver GITHUB-SECRETS-GUIDE.md)

---

## 🚀 Proceso de Despliegue

### 1. Configurar Secrets en GitHub

1. Ve a tu repositorio: `https://github.com/bryanbeltranv/Helm-comment-system`
2. Click en **Settings** → **Secrets and variables** → **Actions**
3. Click en **"New repository secret"**
4. Agrega los 4 secrets (ver [GITHUB-SECRETS-GUIDE.md](GITHUB-SECRETS-GUIDE.md))

### 2. Ejecutar el Workflow Manualmente

**Pasos:**

1. Ve a la pestaña **Actions** en GitHub
2. Selecciona **"Deploy to OpenShift"** en el menú lateral
3. Click en **"Run workflow"** (botón verde a la derecha)
4. Configura:
   ```
   Branch: claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP
   Environment: dev
   ```
5. Click en **"Run workflow"**

### 3. Monitorear el Despliegue

El workflow ejecutará estas fases:

```
✓ Checkout code
✓ Install OpenShift CLI
✓ Install Helm
✓ Login to OpenShift
✓ Set target namespace
✓ Lint Helm chart
✓ Template Helm chart (dry-run)
✓ Deploy with Helm
✓ Verify deployment
✓ Wait for pods to be ready
✓ Get Routes
✓ Run verification script
✓ Deployment Summary
```

**Duración estimada:** 5-10 minutos

### 4. Ver los Logs

1. En **Actions**, click en el workflow que está ejecutándose
2. Click en el job **"deploy"**
3. Verás logs en tiempo real de cada paso

### 5. Obtener la URL de tu Aplicación

Al final del despliegue exitoso, verás:

```
✅ Deployment completed successfully!

📊 Deployment Summary:
- Environment: dev
- Namespace: usuario-dev
- Chart Version: comments-system-1.0.0

🌐 Access your application:
Frontend URL: https://frontend-usuario-dev.apps.sandbox-xxx.openshiftapps.com
```

---

## 🔄 Despliegue Automático

Para habilitar despliegues automáticos:

### 1. Merge a Main

```bash
# Desde tu branch
git checkout main
git merge claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP
git push origin main
```

### 2. Cada Push Desplegará Automáticamente

El workflow se activará cuando:
- Hagas push a `main`
- Y modifiques archivos en:
  - `helm/**/*`
  - `.github/workflows/deploy-openshift.yml`

---

## 🔍 Verificación Post-Despliegue

### Desde GitHub Actions

El workflow ejecuta automáticamente verificaciones:
- ✓ Deployments ready
- ✓ Pods running
- ✓ Services created
- ✓ PVCs bound
- ✓ Routes accessible
- ✓ NetworkPolicies applied

### Verificación Manual desde CLI

```bash
# Login a OpenShift
oc login --token=<TOKEN> --server=<SERVER>

# Cambiar a tu namespace
oc project <NAMESPACE>

# Ver todos los recursos
oc get all

# Ver pods
oc get pods

# Ver routes
oc get routes

# Ver logs del frontend
oc logs -f deployment/frontend

# Ejecutar script de verificación local
./scripts/verify-deployment.sh <NAMESPACE>
```

### Verificación desde Web Console

1. Ve a https://console.redhat.com/openshift/sandbox
2. Selecciona tu proyecto (namespace)
3. Ve a **Topology** para ver todos los servicios
4. Click en cada deployment para ver detalles

---

## 🌐 Acceder a tu Aplicación

### Obtener URL

**Desde GitHub Actions:** Se muestra al final del despliegue

**Desde CLI:**
```bash
oc get route frontend -o jsonpath='{.spec.host}'
```

**Desde Web Console:**
- Topology → Click en el ícono "Open URL" en el nodo frontend

### Probar la Aplicación

```bash
# Obtener URL
FRONTEND_URL=$(oc get route frontend -o jsonpath='{.spec.host}')

# Probar con curl
curl -k https://$FRONTEND_URL

# Probar health endpoints
curl -k http://$(oc get route backend-api -o jsonpath='{.spec.host}')/health
```

---

## 🔧 Troubleshooting

### Workflow Falla en "Login to OpenShift"

**Error:** `error: The server uses a certificate signed by unknown authority`

**Solución:** Verifica que `OPENSHIFT_SERVER` sea correcto y comience con `https://`

### Workflow Falla en "Deploy with Helm"

**Error:** `Error: INSTALLATION FAILED: Kubernetes cluster unreachable`

**Solución:**
1. Verifica que `OPENSHIFT_TOKEN` no haya expirado
2. Genera un nuevo token y actualiza el secret en GitHub

### Pods en Estado "ImagePullBackOff"

**Causa:** Las imágenes de Docker no existen o son privadas

**Solución:**
1. Verifica que las imágenes existan en Docker Hub:
   - `bryanbeltranv/comments-system-frontend:latest`
   - `bryanbeltranv/comments-system-backend-api:latest`
   - `bryanbeltranv/comments-system-backend-data:latest`

2. Si las imágenes son privadas, agrega un ImagePullSecret

### PostgreSQL PVC en Estado "Pending"

**Causa:** OpenShift Sandbox tiene límites de almacenamiento

**Solución:**
1. Reduce el tamaño del PVC en `values/dev.yaml`:
   ```yaml
   persistence:
     size: 1Gi  # en lugar de 5Gi
   ```

### NetworkPolicy Bloquea Conexiones

**Verificar:**
```bash
# Ver NetworkPolicies
oc get networkpolicies

# Probar conectividad
oc exec -it deployment/frontend -- wget -O- http://backend-api:3000/health
```

**Solución:** Si falla, temporalmente deshabilita NetworkPolicies en `values.yaml`:
```yaml
networkPolicies:
  enabled: false
```

---

## 🔄 Actualizar el Despliegue

### Cambiar Configuración

1. Edita `helm/comments-system/values.yaml`
2. Commit y push los cambios
3. El workflow se ejecutará automáticamente (si estás en `main`)

O ejecuta manualmente desde GitHub Actions.

### Rollback

Si el despliegue falla, Helm permite rollback:

```bash
# Ver historial
helm history comments-system -n <NAMESPACE>

# Rollback a versión anterior
helm rollback comments-system -n <NAMESPACE>
```

---

## 📊 Monitoreo

### Ver Logs en Tiempo Real

```bash
# Frontend
oc logs -f deployment/frontend

# Backend API
oc logs -f deployment/backend-api

# Backend Data
oc logs -f deployment/backend-data

# PostgreSQL
oc logs -f deployment/postgres
```

### Ver Eventos

```bash
oc get events --sort-by='.lastTimestamp' | tail -20
```

### Ver Métricas (si disponibles)

```bash
# CPU y memoria de pods
oc top pods

# HPA status
oc get hpa
```

---

## 🎉 Siguiente Paso: Producción

Una vez que dev funcione correctamente:

1. Ejecuta el workflow con `environment: prod`
2. Esto usará `values/prod.yaml` con:
   - Más réplicas
   - Más recursos (CPU/RAM)
   - HPA más agresivo
   - Almacenamiento mayor

---

## 📝 Checklist de Despliegue

- [ ] Secrets configurados en GitHub
- [ ] Workflow ejecutado manualmente primera vez
- [ ] Despliegue completado exitosamente
- [ ] Pods en estado Running
- [ ] Routes accesibles
- [ ] Aplicación responde correctamente
- [ ] Logs no muestran errores críticos
- [ ] Base de datos conectada
- [ ] NetworkPolicies funcionando

---

## 🆘 Soporte

Si tienes problemas:

1. Revisa los logs del workflow en GitHub Actions
2. Ejecuta el script de verificación: `./scripts/verify-deployment.sh`
3. Revisa los logs de los pods: `oc logs -f deployment/<service>`
4. Abre un Issue en el repositorio

---

**Última actualización:** 2025-01-10
