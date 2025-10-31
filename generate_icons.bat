@echo off
REM Script para generar iconos de la aplicacion Renomada
REM Asegurate de tener app_icon.png en assets/icon/ antes de ejecutar

echo ====================================
echo  Generador de Iconos - Renomada
echo ====================================
echo.

REM Verificar que existe el archivo principal
if not exist "assets\icon\app_icon.png" (
    echo ERROR: No se encuentra assets\icon\app_icon.png
    echo.
    echo Por favor, coloca tu icono ^(1024x1024 PNG^) en:
    echo   assets\icon\app_icon.png
    echo.
    echo ^(Opcional^) Para iconos adaptativos, agrega tambien:
    echo   assets\icon\app_icon_foreground.png
    echo.
    pause
    exit /b 1
)

echo OK: Archivo app_icon.png encontrado
echo.

REM Instalar dependencias
echo [1/2] Instalando dependencias...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Fallo la instalacion de dependencias
    pause
    exit /b 1
)
echo.

REM Generar iconos
echo [2/2] Generando iconos para todas las plataformas...
call dart run flutter_launcher_icons
if errorlevel 1 (
    echo ERROR: Fallo la generacion de iconos
    pause
    exit /b 1
)
echo.

echo ====================================
echo  EXITO: Iconos generados correctamente
echo ====================================
echo.
echo Los iconos se generaron en:
echo   - Android: android/app/src/main/res/mipmap-*
echo   - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
echo   - Web: web/icons/
echo.
echo Ahora puedes ejecutar tu app con el nuevo icono.
echo.
pause
