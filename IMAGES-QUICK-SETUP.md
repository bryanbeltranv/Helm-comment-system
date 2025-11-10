# 🐳 Configuración Rápida de Imágenes Docker

## 🎯 Tienes 3 Opciones

### ⚡ Opción 1: Probar con Imágenes Públicas (5 min)

**Usa esto para validar que el Helm Chart funciona correctamente**

```bash
# Usar el archivo de prueba
helm install comments-system ./helm/comments-system \
  -f ./helm/comments-system/values-test.yaml \
  --namespace TU-NAMESPACE \
  --set global.namespace=TU-NAMESPACE
```

O actualiza el workflow de GitHub Actions en `.github/workflows/deploy-openshift.yml`:

```yaml
- name: Deploy with Helm
  run: |
    helm upgrade --install comments-system ${{ env.HELM_CHART_PATH }} \
      --namespace ${{ secrets.OPENSHIFT_NAMESPACE }} \
      --set global.namespace=${{ secrets.OPENSHIFT_NAMESPACE }} \
      --values ${{ env.HELM_CHART_PATH }}/values-test.yaml \  # ← Cambia esta línea
      --timeout 10m \
      --wait
```

✅ **Ventajas:** Funciona inmediatamente, sin necesidad de crear imágenes
⚠️ **Limitación:** No son tus aplicaciones reales, solo para probar el despliegue

---

### 🔧 Opción 2: Usar tus Propias Imágenes (20-30 min)

**Si ya tienes tus imágenes en Docker Hub:**

#### Método A: Usar el script automático

```bash
# Actualizar values.yaml automáticamente
./scripts/update-images.sh TU-USUARIO-DOCKERHUB

# Ejemplo:
./scripts/update-images.sh juanperez
```

Esto cambiará automáticamente:
- `bryanbeltranv/comments-system-frontend` → `juanperez/comments-system-frontend`
- `bryanbeltranv/comments-system-backend-api` → `juanperez/comments-system-backend-api`
- `bryanbeltranv/comments-system-backend-data` → `juanperez/comments-system-backend-data`

Luego:
```bash
git add helm/comments-system/values.yaml
git commit -m "Update Docker images to juanperez"
git push
```

#### Método B: Editar manualmente

Abre `helm/comments-system/values.yaml` y cambia:

```yaml
microservices:
  - name: frontend
    image:
      repository: TU-USUARIO/TU-IMAGEN-FRONTEND  # ← Cambia esto
      tag: latest

  - name: backend-api
    image:
      repository: TU-USUARIO/TU-IMAGEN-API      # ← Cambia esto
      tag: latest

  - name: backend-data
    image:
      repository: TU-USUARIO/TU-IMAGEN-DATA     # ← Cambia esto
      tag: latest
```

#### Verificar que las imágenes existen:

```bash
docker pull TU-USUARIO/TU-IMAGEN-FRONTEND:latest
docker pull TU-USUARIO/TU-IMAGEN-API:latest
docker pull TU-USUARIO/TU-IMAGEN-DATA:latest
```

Si funciona → ✅ Las imágenes existen
Si falla → ❌ Necesitas crear y subir las imágenes primero

---

### 🏗️ Opción 3: Crear y Subir tus Imágenes (1-2 horas)

**Si NO tienes las imágenes todavía:**

#### Paso 1: Crear Dockerfiles

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

#### Paso 2: Construir y Subir

```bash
# Login a Docker Hub
docker login

# Frontend
cd frontend
docker build -t TU-USUARIO/comments-frontend:latest .
docker push TU-USUARIO/comments-frontend:latest

# Backend API
cd ../backend-api
docker build -t TU-USUARIO/comments-api:latest .
docker push TU-USUARIO/comments-api:latest

# Backend Data
cd ../backend-data
docker build -t TU-USUARIO/comments-data:latest .
docker push TU-USUARIO/comments-data:latest
```

#### Paso 3: Actualizar values.yaml

Usa el script:
```bash
./scripts/update-images.sh TU-USUARIO
```

O edita manualmente con los nombres exactos de tus imágenes.

---

## 🚀 Proceso Completo Recomendado

### Para Primera Vez (Validar Despliegue):

```bash
# 1. Probar con imágenes de prueba
git checkout -b test-deployment

# 2. Actualizar workflow para usar values-test.yaml
# Edita: .github/workflows/deploy-openshift.yml
# Línea: --values ${{ env.HELM_CHART_PATH }}/values-test.yaml

# 3. Commit y push
git add .github/workflows/deploy-openshift.yml
git commit -m "Test deployment with public images"
git push -u origin test-deployment

# 4. Ejecutar workflow desde GitHub Actions
# Si todo funciona → ✅ Tu Helm Chart está bien configurado
```

### Para Producción (Con tus Imágenes):

```bash
# 1. Crear y subir tus imágenes a Docker Hub
docker login
docker build -t usuario/imagen:tag .
docker push usuario/imagen:tag

# 2. Actualizar values.yaml
./scripts/update-images.sh TU-USUARIO

# 3. Commit y push
git add helm/comments-system/values.yaml
git commit -m "Update to production images"
git push

# 4. Ejecutar workflow de GitHub Actions
# Ahora desplegará TUS aplicaciones reales
```

---

## 📝 Checklist

**Antes de desplegar, verifica:**

- [ ] Las imágenes existen en Docker Hub (o las usas de prueba)
- [ ] Puedes hacer `docker pull` de cada imagen
- [ ] Los nombres en `values.yaml` coinciden con Docker Hub
- [ ] Los tags son correctos (latest, v1.0, etc.)
- [ ] Los puertos configurados son correctos
- [ ] Si son privadas, tienes ImagePullSecret configurado

---

## 🆘 Troubleshooting

### Error: "ImagePullBackOff"

```bash
# Ver detalles del error
oc describe pod NOMBRE-POD

# Verificar que puedes bajar la imagen
docker pull USUARIO/IMAGEN:TAG
```

**Soluciones:**
- La imagen no existe → Crearla y subirla
- La imagen es privada → Configurar ImagePullSecret
- El nombre está mal → Corregir en values.yaml

### Error: "CrashLoopBackOff"

```bash
# Ver logs del contenedor
oc logs NOMBRE-POD

# Ver eventos
oc get events --sort-by='.lastTimestamp' | tail -20
```

**Soluciones:**
- Verificar que los puertos son correctos
- Verificar variables de entorno
- Verificar que la aplicación inicia correctamente

---

## 📚 Guías Completas

- **[DOCKER-IMAGES-GUIDE.md](DOCKER-IMAGES-GUIDE.md)** - Guía completa sobre imágenes
- **[QUICK-START.md](QUICK-START.md)** - Despliegue en 5 minutos
- **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Guía completa de despliegue

---

## 💡 Tips

1. **Usa tags específicos en producción:**
   ```yaml
   tag: v1.0.0  # En lugar de 'latest'
   ```

2. **Verifica las imágenes antes de desplegar:**
   ```bash
   docker pull usuario/imagen:tag
   ```

3. **Mantén un backup del values.yaml original:**
   ```bash
   cp values.yaml values.yaml.backup
   ```

4. **Para desarrollo, usa `pullPolicy: Always`:**
   ```yaml
   pullPolicy: Always  # Siempre baja la última versión
   ```

5. **Para producción, usa `pullPolicy: IfNotPresent`:**
   ```yaml
   pullPolicy: IfNotPresent  # Más eficiente
   ```

---

**Última actualización:** 2025-01-10
