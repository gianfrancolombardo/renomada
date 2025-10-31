@echo off
echo Building Flutter web release...
flutter build web --release
if %errorlevel% neq 0 (
    echo Build failed!
    exit /b %errorlevel%
)

echo Deploying to Firebase Hosting...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo Deploy failed!
    exit /b %errorlevel%
)

echo Deploy completed successfully!