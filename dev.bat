@echo off
echo Starting Flutter development server on Chrome with fixed port...
echo Optional: append --dart-define=ONESIGNAL_APP_ID=your-onesignal-app-id
flutter run -d chrome --web-port=8080 %*
