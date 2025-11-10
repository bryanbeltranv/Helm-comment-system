# 🔧 Solución: Error de Despliegue

## 📋 Problemas Detectados

### 1. ❌ Helm Bloqueado
```
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```

### 2. ❌ Imágenes con Nombres Viejos
El despliegue intenta descargar:
- `bryanbeltranv/comments-system-frontend:latest` ❌
- `bryanbeltranv/comments-system-backend-api:latest` ❌
- `bryanbeltranv/comments-system-backend-data:latest` ❌

Pero las imágenes correctas son:
- `bryanbeltranv/frontend:latest` ✅
- `bryanbeltranv/backend-api:tagname` ✅
- `bryanbeltranv/backend-data:latest` ✅

**Causa:** El workflow ejecutó con una versión vieja del código (antes del commit que actualizó las imágenes).

---

## 🚀 Solución Completa (3 Opciones)

### ⚡ OPCIÓN 1: Solución Rápida desde GitHub (Recomendada)

#### Paso 1: Limpiar el Release Bloqueado

Necesitas acceso CLI a OpenShift. Ejecuta:

```bash
# Login a OpenShift
oc login --token=<TU-TOKEN> --server=<TU-SERVER>

# Cambiar a tu namespace
oc project <TU-NAMESPACE>

# Desinstalar el release bloqueado
helm uninstall comments-system -n <TU-NAMESPACE>
```

**O si quieres conservar datos:**
```bash
# Rollback a la versión anterior
helm rollback comments-system -n <TU-NAMESPACE>
```

#### Paso 2: Verificar que el Branch tiene las Imágenes Correctas

```bash
# Desde tu repositorio local
git log --oneline -5

# Debes ver este commit:
# 1253543 Update Docker images to production values
```

#### Paso 3: Re-ejecutar el Workflow

1. Ve a **GitHub → Actions**
2. Click en **"Deploy to OpenShift"**
3. Click en **"Run workflow"**
4. **IMPORTANTE:** Asegúrate de seleccionar:
   - **Branch:** `claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP` ✅
   - **Environment:** `dev`
5. Click **"Run workflow"**

Esto ejecutará con las imágenes correctas.

---

### 🔧 OPCIÓN 2: Fix Completo desde CLI

```bash
# 1. Login a OpenShift
oc login --token=<TOKEN> --server=<SERVER>
oc project <NAMESPACE>

# 2. Limpiar release bloqueado
helm uninstall comments-system -n <NAMESPACE>

# 3. Clonar el repo (si no lo tienes)
git clone https://github.com/bryanbeltranv/Helm-comment-system.git
cd Helm-comment-system

# 4. Cambiar al branch correcto
git checkout claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP
git pull origin claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP

# 5. Verificar que las imágenes son correctas
grep -A 2 "repository:" helm/comments-system/values.yaml

# Debes ver:
# repository: bryanbeltranv/frontend
# repository: bryanbeltranv/backend-api
# repository: bryanbeltranv/backend-data

# 6. Instalar con Helm
helm install comments-system ./helm/comments-system \
  --namespace <NAMESPACE> \
  --set global.namespace=<NAMESPACE> \
  --set global.domain=<DOMAIN> \
  --values ./helm/comments-system/values.yaml \
  --wait \
  --timeout 10m
```

---

### 🏗️ OPCIÓN 3: Verificar que las Imágenes Existen

Antes de volver a desplegar, verifica que las imágenes existen:

```bash
# Verificar que puedes descargar las imágenes
docker pull bryanbeltranv/frontend:latest
docker pull bryanbeltranv/backend-api:tagname
docker pull bryanbeltranv/backend-data:latest
```

**Si falla con "access denied" o "manifest unknown":**
- Las imágenes NO existen en Docker Hub
- Las imágenes son privadas (necesitas configurar ImagePullSecret)

#### Si las imágenes NO existen:

**Opción A:** Usar imágenes de prueba temporalmente

Edita el workflow para usar `values-test.yaml`:
```yaml
# .github/workflows/deploy-openshift.yml línea 72
--values ${{ env.HELM_CHART_PATH }}/values-test.yaml \
```

**Opción B:** Crear y subir las imágenes

```bash
# Crear las imágenes
cd frontend
docker build -t bryanbeltranv/frontend:latest .
docker push bryanbeltranv/frontend:latest

cd ../backend-api
docker build -t bryanbeltranv/backend-api:tagname .
docker push bryanbeltranv/backend-api:tagname

cd ../backend-data
docker build -t bryanbeltranv/backend-data:latest .
docker push bryanbeltranv/backend-data:latest
```

---

## 🎯 Proceso Recomendado (Orden de Pasos)

### 1️⃣ Limpiar el Helm Release Bloqueado

```bash
oc login --token=<TOKEN> --server=<SERVER>
oc project <NAMESPACE>
helm uninstall comments-system -n <NAMESPACE>
```

### 2️⃣ Verificar Imágenes (MUY IMPORTANTE)

```bash
# ¿Las imágenes existen?
docker pull bryanbeltranv/frontend:latest
docker pull bryanbeltranv/backend-api:tagname
docker pull bryanbeltranv/backend-data:latest
```

**Si TODAS funcionan:**
✅ Continúa al paso 3

**Si ALGUNA falla:**
❌ Ve a "Opción 3" arriba para crear las imágenes o usar imágenes de prueba

### 3️⃣ Re-ejecutar el Workflow

```
GitHub → Actions → Deploy to OpenShift → Run workflow
Branch: claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP
Environment: dev
```

---

## 📊 Verificar el Despliegue

Después del despliegue:

```bash
# Ver estado de pods
oc get pods -n <NAMESPACE>

# Todos deben estar en "Running" y "Ready 1/1"

# Ver logs si hay errores
oc logs -f deployment/frontend -n <NAMESPACE>

# Obtener URL
oc get route frontend -n <NAMESPACE> -o jsonpath='{.spec.host}'
```

---

## 🆘 Troubleshooting Adicional

### Error: "ImagePullBackOff"

**Causa:** La imagen no existe o es privada

**Solución:**
```bash
# Verificar en Docker Hub
# https://hub.docker.com/u/bryanbeltranv

# Si son privadas, crear ImagePullSecret:
oc create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=bryanbeltranv \
  --docker-password=<PASSWORD> \
  -n <NAMESPACE>
```

Y agregar al `templates/deployment.yaml`:
```yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: dockerhub-secret
```

### Error: "CrashLoopBackOff"

**Causa:** La imagen se descarga pero la aplicación falla al iniciar

**Solución:**
```bash
# Ver logs del pod
oc logs <POD-NAME> -n <NAMESPACE>

# Verificar:
# - Puertos correctos en values.yaml
# - Variables de entorno correctas
# - La aplicación inicia correctamente
```

---

## 📝 Checklist Final

Antes de volver a desplegar:

- [ ] Helm release limpiado (`helm uninstall` ejecutado)
- [ ] Imágenes verificadas (`docker pull` funciona para todas)
- [ ] Branch correcto seleccionado en GitHub Actions
- [ ] Secrets de GitHub configurados
- [ ] Namespace correcto en OpenShift

---

## 💡 Tips para Evitar este Error en el Futuro

1. **Siempre verifica que las imágenes existen:**
   ```bash
   ./scripts/verify-images.sh
   ```

2. **Usa el branch correcto en GitHub Actions:**
   - Verifica que seleccionaste el branch con los commits más recientes

3. **Revisa los logs del workflow:**
   - Busca qué imágenes está intentando descargar
   - Compara con tu `values.yaml` local

4. **Para development, usa `values-test.yaml`:**
   - Contiene imágenes públicas que siempre funcionan
   - Perfecto para validar que el Helm chart funciona

---

**Última actualización:** 2025-01-10
