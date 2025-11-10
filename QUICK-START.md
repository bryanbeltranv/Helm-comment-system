# 🚀 Quick Start - Despliegue en 5 Minutos

## Paso 1️⃣: Obtener Credenciales de OpenShift (2 min)

```bash
# 1. Abre OpenShift Sandbox
https://console.redhat.com/openshift/sandbox

# 2. Click en tu nombre → "Copy login command"
# 3. Click "Display Token"
# 4. Copia estos valores:
```

**Necesitas copiar:**
- `--token=` → Este es tu **OPENSHIFT_TOKEN**
- `--server=` → Este es tu **OPENSHIFT_SERVER**
- Tu proyecto/namespace → **OPENSHIFT_NAMESPACE**

Para obtener el dominio:
```bash
oc get route -n openshift-console
# Verás: console-openshift-console.apps.sandbox-XXX.openshiftapps.com
# Copia: apps.sandbox-XXX.openshiftapps.com (esto es OPENSHIFT_DOMAIN)
```

---

## Paso 2️⃣: Configurar Secrets en GitHub (1 min)

1. Ve a: `https://github.com/TU-USUARIO/Helm-comment-system/settings/secrets/actions`
2. Click **"New repository secret"** 4 veces y agrega:

| Name | Value |
|------|-------|
| `OPENSHIFT_TOKEN` | `sha256~xxxxx...` (del paso 1) |
| `OPENSHIFT_SERVER` | `https://api.sandbox-xxx.openshiftapps.com:6443` |
| `OPENSHIFT_NAMESPACE` | `tu-usuario-dev` |
| `OPENSHIFT_DOMAIN` | `apps.sandbox-xxx.openshiftapps.com` |

---

## Paso 3️⃣: Desplegar (1 min)

1. Ve a la pestaña **Actions** en GitHub
2. Click en **"Deploy to OpenShift"** (menú izquierdo)
3. Click botón verde **"Run workflow"**
4. Selecciona:
   - **Branch:** `claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP`
   - **Environment:** `dev`
5. Click **"Run workflow"**

⏱️ **Espera 5-10 minutos** mientras se despliega...

---

## Paso 4️⃣: Obtener URL de tu App (30 seg)

Al finalizar el workflow, verás:

```
🌐 Access your application:
Frontend URL: https://frontend-usuario-dev.apps.sandbox-xxx.openshiftapps.com
```

O desde CLI:
```bash
oc get route frontend -o jsonpath='{.spec.host}'
```

**Abre esa URL en tu navegador** 🎉

---

## 🔍 Verificar que Todo Funciona

```bash
# Login
oc login --token=<TOKEN> --server=<SERVER>

# Ver recursos
oc get pods
oc get routes

# Ver logs
oc logs -f deployment/frontend
```

---

## 🎯 Siguiente Paso

¿Todo funciona? Perfecto! Ahora puedes:

1. **Merge a main** para despliegues automáticos:
   ```bash
   git checkout main
   git merge claude/k8s-deployment-spec-011CUzp6qW4Kt6SCuEcYi8tP
   git push origin main
   ```

2. **Desplegar a producción:**
   - Actions → Run workflow
   - Environment: **prod**

---

## ❌ ¿Algo salió mal?

**Ver logs del workflow:**
- Actions → Click en el workflow → Ver logs

**Troubleshooting:**
- [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) - Guía completa
- [README.md](README.md) - Documentación técnica

**Comandos útiles:**
```bash
# Ver estado de pods
oc get pods

# Ver eventos recientes
oc get events --sort-by='.lastTimestamp' | tail -20

# Ver logs de un pod específico
oc logs <POD-NAME>

# Ejecutar script de verificación
./scripts/verify-deployment.sh <NAMESPACE>
```

---

## 📋 Checklist

- [ ] Secrets configurados en GitHub
- [ ] Workflow ejecutado
- [ ] Pods en estado Running (`oc get pods`)
- [ ] Route del frontend funciona
- [ ] Aplicación accesible en el navegador

---

¡Listo! Tu sistema de comentarios está desplegado en OpenShift 🚀
