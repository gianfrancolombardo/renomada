# Setup CI/CD con GitHub Actions

Este documento explica cómo configurar el despliegue automático a Firebase Hosting usando GitHub Actions.

## 🚀 Configuración Inicial

### 1. Obtener el Token de Firebase

1. Instala Firebase CLI globalmente (si no lo tienes):
   ```bash
   npm install -g firebase-tools
   ```

2. Inicia sesión en Firebase:
   ```bash
   firebase login
   ```

3. Genera un token de CI:
   ```bash
   firebase login:ci
   ```

4. Copia el token que se muestra (algo como: `1//abc123def456...`)

### 2. Configurar el Secret en GitHub

1. Ve a tu repositorio en GitHub
2. Haz clic en **Settings** (Configuración)
3. En el menú lateral, selecciona **Secrets and variables** → **Actions**
4. Haz clic en **New repository secret**
5. Nombre: `FIREBASE_TOKEN`
6. Valor: Pega el token que copiaste en el paso anterior
7. Haz clic en **Add secret**

### 3. Verificar el Branch

El workflow está configurado para ejecutarse en el branch `main`. Si tu branch principal es `master`, edita `.github/workflows/deploy.yml` y cambia:

```yaml
branches:
  - main  # Cambia esto si es necesario
```

### 4. Verificar la Versión de Flutter

Abre `.github/workflows/deploy.yml` y ajusta la versión de Flutter si es necesario:

```yaml
flutter-version: '3.24.0'  # Ajusta a tu versión
```

Puedes verificar tu versión con:
```bash
flutter --version
```

## ✅ ¿Cómo Funciona?

Cada vez que hagas `git push` al branch `main`, GitHub Actions automáticamente:

1. ✅ Hace checkout del código
2. ✅ Configura Flutter
3. ✅ Obtiene las dependencias (`flutter pub get`)
4. ✅ Compila la app web (`flutter build web --release`)
5. ✅ Instala Firebase CLI
6. ✅ Despliega a Firebase Hosting

## 📋 Verificar el Deploy

1. Ve a la pestaña **Actions** en tu repositorio de GitHub
2. Verás el workflow ejecutándose
3. Si todo sale bien, verás un check verde ✅
4. Si hay errores, verás un X rojo ❌ y podrás ver los logs

## 🔧 Troubleshooting

### El workflow falla en "Build Flutter web"

- Verifica que todas las dependencias estén correctamente configuradas en `pubspec.yaml`
- Asegúrate de que la versión de Flutter en el workflow coincida con la que usas localmente

### El workflow falla en "Deploy to Firebase Hosting"

- Verifica que el token `FIREBASE_TOKEN` esté correctamente configurado en GitHub Secrets
- Asegúrate de que `firebase.json` y `.firebaserc` estén en el repositorio
- Verifica que el proyecto de Firebase en `.firebaserc` sea correcto

### Quiero desplegar desde otro branch

Edita `.github/workflows/deploy.yml`:

```yaml
on:
  push:
    branches:
      - main
      - develop  # Agrega aquí otros branches
```

## 🛠️ Deploy Manual (deploy.bat)

Si prefieres hacer deploy manualmente, usa el archivo `deploy.bat`:

```bash
deploy.bat
```

Este script:
1. Compila Flutter web en modo release
2. Despliega a Firebase Hosting

**Nota:** Asegúrate de estar autenticado con Firebase (`firebase login`) antes de ejecutar el script.

