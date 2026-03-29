// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

/// Calls [web/onesignal_bridge.js] functions on `globalThis`.
Future<void> onesignalWebInit(String appId) async {
  await js_util.promiseToFuture<Object?>(
    js_util.callMethod(js_util.globalThis, 'renomadaOneSignalInit', [appId]),
  );
}

Future<String?> onesignalWebLogin(String externalId) async {
  final r = await js_util.promiseToFuture<Object?>(
    js_util.callMethod(js_util.globalThis, 'renomadaOneSignalLogin', [externalId]),
  );
  if (r == null) return null;
  if (r is String) return r.isEmpty ? null : r;
  return r.toString();
}

Future<void> onesignalWebLogout() async {
  await js_util.promiseToFuture<Object?>(
    js_util.callMethod(js_util.globalThis, 'renomadaOneSignalLogout', []),
  );
}

void onesignalWebSetClickHandler(void Function(Map<String, dynamic>) onClick) {
  js_util.setProperty(
    js_util.globalThis,
    'renomadaOnOneSignalNotificationClick',
    js_util.allowInterop((Object? jsonString) {
      final s = jsonString?.toString();
      if (s == null || s.isEmpty) return;
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          onClick(decoded);
        } else if (decoded is Map) {
          onClick(Map<String, dynamic>.from(decoded));
        }
      } catch (e) {
        debugPrint('onesignalWeb click: $e');
      }
    }),
  );
}

void onesignalWebSetSubscriptionHandler(void Function(String id) onId) {
  js_util.setProperty(
    js_util.globalThis,
    'renomadaOnOneSignalSubscriptionChange',
    js_util.allowInterop((Object? id) {
      final s = id?.toString();
      if (s != null && s.isNotEmpty) onId(s);
    }),
  );
}
