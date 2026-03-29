@echo off
setlocal

echo Building Flutter web release...
flutter build web --release
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Deploying to Firebase Hosting...
firebase deploy --only hosting
if errorlevel 1 (
    echo Deploy failed!
    exit /b 1
)

echo Deploy completed successfully!