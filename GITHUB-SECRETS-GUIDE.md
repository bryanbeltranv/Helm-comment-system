# Guía: Obtener Valores para GitHub Secrets

## 1. OPENSHIFT_TOKEN

### Opción A: Desde OpenShift Web Console
1. Abre https://console.redhat.com/openshift/sandbox
2. Click en tu nombre (esquina superior derecha) → "Copy login command"
3. Se abrirá una nueva ventana → Click "Display Token"
4. Copia el valor que aparece después de `--token=`

### Opción B: Desde CLI (si ya estás logueado)
```bash
oc whoami -t
```

**Ejemplo de valor:**
```
sha256~abcdef1234567890XXXXXXXXXXXXXXXXXXXXXXXX
```

---

## 2. OPENSHIFT_SERVER

En la misma página donde obtuviste el token, verás:
```bash
oc login --token=sha256~xxx... --server=https://api.sandbox-xxx.openshiftapps.com:6443
```

Copia la URL del `--server=`

**Ejemplo de valor:**
```
https://api.sandbox-m99.openshiftapps.com:6443
```

---

## 3. OPENSHIFT_NAMESPACE

### Desde Web Console:
- Ve al dashboard de OpenShift
- En la esquina superior izquierda verás: "Project: usuario-dev" (o similar)
- Ese es tu namespace

### Desde CLI:
```bash
oc project
```

**Ejemplo de valor:**
```
usuario-dev
```

---

## 4. OPENSHIFT_DOMAIN

Este es el dominio base de tu cluster de OpenShift Sandbox.

**Para OpenShift Sandbox, típicamente es:**
```
apps.sandbox-m99.openshiftapps.com
```

Para confirmarlo:
```bash
oc get route -n openshift-console
```

Verás algo como: `console-openshift-console.apps.sandbox-m99.openshiftapps.com`

Usa la parte después del primer punto: `apps.sandbox-m99.openshiftapps.com`

**Ejemplo de valor:**
```
apps.sandbox-m99.openshiftapps.com
```

---

## Resumen de Secrets a Configurar en GitHub

| Secret Name | Ejemplo |
|-------------|---------|
| `OPENSHIFT_TOKEN` | `sha256~abcdef1234567890...` |
| `OPENSHIFT_SERVER` | `https://api.sandbox-m99.openshiftapps.com:6443` |
| `OPENSHIFT_NAMESPACE` | `usuario-dev` |
| `OPENSHIFT_DOMAIN` | `apps.sandbox-m99.openshiftapps.com` |

---

## Validar tu Configuración Localmente

Antes de configurar GitHub, prueba estos comandos localmente:

```bash
# Login
oc login --token=<TU-TOKEN> --server=<TU-SERVER>

# Verificar namespace
oc project <TU-NAMESPACE>

# Verificar acceso
oc get pods
```

Si todo funciona localmente, entonces los valores son correctos para GitHub Secrets.
