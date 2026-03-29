/// OneSignal Dashboard → Settings → Keys & IDs → **OneSignal App ID** (safe to embed).
///
/// Prefer: `flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id`
/// If empty, push initialization is skipped and the rest of the app still runs.
class OnesignalConstants {
  OnesignalConstants._();

  static const String appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'ddc5e614-2b24-4c76-8f43-2f45e52601c6',
  );
}
