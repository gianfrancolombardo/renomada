import 'dart:async';

/// Non-web: no-op bridge (mobile uses `onesignal_flutter` directly).
Future<void> onesignalWebInit(String appId) async {}

Future<String?> onesignalWebLogin(String externalId) async => null;

Future<void> onesignalWebLogout() async {}

void onesignalWebSetClickHandler(void Function(Map<String, dynamic>) onClick) {}

void onesignalWebSetSubscriptionHandler(void Function(String id) onId) {}
