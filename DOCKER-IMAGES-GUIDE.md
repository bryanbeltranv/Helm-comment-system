# 🐳 Guía: Configuración de Imágenes Docker

## 📋 Imágenes Configuradas Actualmente

El archivo `helm/comments-system/values.yaml` tiene estas imágenes configuradas:

```yaml
# Frontend
repository: bryanbeltranv/comments-system-frontend
tag: latest

# Backend API
repository: bryanbeltranv/comments-system-backend-api
tag: latest

# Backend Data
repository: bryanbeltranv/comments-system-backend-data
tag: latest

# PostgreSQL (imagen pública oficial)
repository: postgres
tag: 15-alpine
```

⚠️ **IMPORTANTE:** Las primeras 3 imágenes son **placeholders** y probablemente no existen en Docker Hub. Necesitas usar tus propias imágenes.

---

## 🎯 Opción 1: Usar tus Propias Imágenes (Recomendado)

### Si ya tienes las imágenes en Docker Hub:

Edita `helm/comments-system/values.yaml` y cambia los repositorios:

```yaml
microservices:
  - name: frontend
    image:
      repository: TU-USUARIO/TU-IMAGEN-FRONTEND
      tag: latest

  - name: backend-api
    image:
      repository: TU-USUARIO/TU-IMAGEN-BACKEND-API
      tag: latest

  - name: backend-data
    image:
      repository: TU-USUARIO/TU-IMAGEN-BACKEND-DATA
      tag: latest
```

**Ejemplo:**
```yaml
repository: juanperez/comments-frontend
tag: v1.0.0
```

### Si NO tienes las imágenes todavía:

#### Paso 1: Crear Dockerfiles para cada servicio

**Frontend (Dockerfile):**
```dockerfile
FROM nginx:alpine
COPY ./build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Backend API (Dockerfile):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

**Backend Data (Dockerfile):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]
```

#### Paso 2: Construir y subir las imágenes

```bash
# Login a Docker Hub
docker login

# Frontend
cd frontend
docker build -t TU-USUARIO/comments-frontend:latest .
docker push TU-USUARIO/comments-frontend:latest

# Backend API
cd ../backend-api
docker build -t TU-USUARIO/comments-backend-api:latest .
docker push TU-USUARIO/comments-backend-api:latest

# Backend Data
cd ../backend-data
docker build -t TU-USUARIO/comments-backend-data:latest .
docker push TU-USUARIO/comments-backend-data:latest
```

#### Paso 3: Actualizar values.yaml

```yaml
microservices:
  - name: frontend
    image:
      repository: TU-USUARIO/comments-frontend
      tag: latest

  - name: backend-api
    image:
      repository: TU-USUARIO/comments-backend-api
      tag: latest

  - name: backend-data
    image:
      repository: TU-USUARIO/comments-backend-data
      tag: latest
```

---

## 🎯 Opción 2: Usar Imágenes de Prueba Públicas (Desarrollo)

Para probar el despliegue sin tener las imágenes reales, puedes usar imágenes de prueba:

```yaml
microservices:
  - name: frontend
    image:
      repository: nginx
      tag: alpine
    port: 80
    targetPort: 80

  - name: backend-api
    image:
      repository: hashicorp/http-echo
      tag: latest
    port: 3000
    targetPort: 5678
    env:
      - name: PORT
        value: "5678"

  - name: backend-data
    image:
      repository: hashicorp/http-echo
      tag: latest
    port: 3001
    targetPort: 5678
    env:
      - name: PORT
        value: "5678"

  - name: postgres
    image:
      repository: postgres
      tag: "15-alpine"
    # Esta ya funciona, no cambiarla
```

⚠️ **Nota:** Estas son solo para **probar que el Helm chart funciona**. NO son tus aplicaciones reales.

---

## 🎯 Opción 3: Sobrescribir Imágenes desde GitHub Actions

Sin modificar `values.yaml`, puedes sobrescribir las imágenes en el workflow:

Edita `.github/workflows/deploy-openshift.yml`:

```yaml
- name: Deploy with Helm
  run: |
    helm upgrade --install comments-system ${{ env.HELM_CHART_PATH }} \
      --namespace ${{ secrets.OPENSHIFT_NAMESPACE }} \
      --set global.namespace=${{ secrets.OPENSHIFT_NAMESPACE }} \
      --set global.domain=${{ secrets.OPENSHIFT_DOMAIN }} \
      --set microservices[0].image.repository=${{ secrets.DOCKER_USERNAME }}/comments-frontend \
      --set microservices[1].image.repository=${{ secrets.DOCKER_USERNAME }}/comments-backend-api \
      --set microservices[2].image.repository=${{ secrets.DOCKER_USERNAME }}/comments-backend-data \
      --values ${{ env.HELM_CHART_PATH }}/values.yaml \
      --timeout 10m \
      --wait
```

Y agrega un secret `DOCKER_USERNAME` en GitHub con tu usuario de Docker Hub.

---

## 🔐 Si tus Imágenes son Privadas

Si tus imágenes están en un repositorio privado de Docker Hub, necesitas crear un ImagePullSecret:

### Paso 1: Crear Secret en OpenShift

```bash
oc create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=TU-USUARIO \
  --docker-password=TU-PASSWORD \
  --docker-email=TU-EMAIL \
  -n TU-NAMESPACE
```

### Paso 2: Agregar al values.yaml

Edita `helm/comments-system/templates/deployment.yaml` y agrega:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: dockerhub-secret
      containers:
        - name: {{ $service.name }}
          # ... resto de la configuración
```

---

## 📝 Checklist de Imágenes

Antes de desplegar, verifica:

- [ ] Las imágenes existen en Docker Hub (o tu registry)
- [ ] Puedes hacer `docker pull` de cada imagen
- [ ] Si son privadas, tienes ImagePullSecret configurado
- [ ] Los tags son correctos (latest, v1.0, etc.)
- [ ] Los puertos de las imágenes coinciden con el values.yaml

### Verificar que las imágenes existen:

```bash
# Verificar imagen pública
docker pull TU-USUARIO/comments-frontend:latest

# Si funciona, la imagen existe y es pública ✅
# Si falla, la imagen no existe o es privada ❌
```

---

## 🔄 Proceso Recomendado

1. **Desarrollo Local:**
   - Crea tus Dockerfiles
   - Prueba localmente: `docker build` y `docker run`
   - Verifica que funcionen correctamente

2. **Subir a Docker Hub:**
   - `docker login`
   - `docker build -t usuario/imagen:tag .`
   - `docker push usuario/imagen:tag`

3. **Actualizar Helm Chart:**
   - Edita `values.yaml` con tus imágenes
   - Commit y push los cambios

4. **Desplegar:**
   - Ejecuta el workflow de GitHub Actions
   - Verifica que los pods arranquen correctamente

---

## 🐛 Troubleshooting

### Error: "ImagePullBackOff" o "ErrImagePull"

**Causa:** La imagen no existe o no es accesible.

**Solución:**
```bash
# Verificar que puedes hacer pull de la imagen
docker pull USUARIO/IMAGEN:TAG

# Si falla, la imagen no existe o necesitas imagePullSecret
```

### Error: "CrashLoopBackOff"

**Causa:** La imagen existe pero la aplicación falla al iniciar.

**Solución:**
```bash
# Ver logs del pod
oc logs POD-NAME

# Verificar configuración de puertos y variables de entorno en values.yaml
```

### Las imágenes se actualizan pero el pod usa la versión antigua

**Causa:** El tag `latest` está cacheado.

**Solución:**
```yaml
# En values.yaml, cambiar pullPolicy:
image:
  pullPolicy: Always  # Forzar a bajar siempre la imagen
```

---

## 📚 Ejemplos Completos

### Ejemplo con Docker Hub público:

```yaml
# values.yaml
microservices:
  - name: frontend
    image:
      repository: juanperez/mi-frontend
      tag: v1.2.3
      pullPolicy: Always
```

### Ejemplo con múltiples tags:

```yaml
# Desarrollo
tag: latest

# Producción (values/prod.yaml)
tag: v1.0.0
```

### Ejemplo con registry alternativo (no Docker Hub):

```yaml
# values.yaml
global:
  registry: quay.io  # o ghcr.io, gcr.io, etc.

microservices:
  - name: frontend
    image:
      repository: quay.io/usuario/imagen
      tag: latest
```

---

## 🎯 Recomendación

**Para empezar rápido:**
1. Usa la **Opción 2** (imágenes de prueba públicas) para validar que el Helm chart funciona
2. Luego crea tus propias imágenes (**Opción 1**)
3. Actualiza `values.yaml` con tus imágenes reales
4. Redespliega

**Para producción:**
- Usa tags específicos (v1.0.0, v1.0.1) en lugar de `latest`
- Mantén tus imágenes en un registry privado
- Usa ImagePullSecrets para seguridad

---

**Última actualización:** 2025-01-10
