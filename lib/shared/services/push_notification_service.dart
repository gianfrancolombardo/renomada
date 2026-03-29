import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/onesignal_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/router/app_router.dart';
import 'onesignal_interop_stub.dart'
    if (dart.library.html) 'onesignal_interop_web.dart' as onesignal_bridge;

/// OneSignal push: Supabase `user.id` is the external id (matches n8n
/// `include_external_user_ids`). Subscription id is stored in [push_tokens]
/// for server-side RPCs.
///
/// **Web:** OneSignal Web SDK v16 via [web/onesignal_bridge.js] + `dart:js_util`.
/// **Mobile:** `onesignal_flutter` (Android / iOS).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  bool _nativeClickListenerAttached = false;
  bool _nativeSubscriptionObserverAttached = false;

  bool get isConfigured => OnesignalConstants.appId.isNotEmpty;

  Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        'OneSignal: no ONESIGNAL_APP_ID (dart-define); push disabled.',
      );
      return;
    }
    if (_initialized) return;

    if (kIsWeb) {
      try {
        debugPrint(
          '[OneSignal Web] initializing (see browser console: [ReNomada OneSignal])…',
        );
        await onesignal_bridge.onesignalWebInit(OnesignalConstants.appId);
        onesignal_bridge.onesignalWebSetClickHandler(_onWebNotificationData);
        onesignal_bridge.onesignalWebSetSubscriptionHandler(
          (id) => unawaited(persistSubscriptionId(id)),
        );
        _initialized = true;
        debugPrint('[OneSignal Web] Dart: init completed, handlers registered.');
      } catch (e) {
        debugPrint('[OneSignal Web] init failed: $e');
      }
      return;
    }

    _initialized = true;

    await OneSignal.Debug.setLogLevel(
      kDebugMode ? OSLogLevel.verbose : OSLogLevel.warn,
    );
    await OneSignal.initialize(OnesignalConstants.appId);

    if (!_nativeClickListenerAttached) {
      _nativeClickListenerAttached = true;
      OneSignal.Notifications.addClickListener(_onNativeNotificationClicked);
    }

    if (!_nativeSubscriptionObserverAttached) {
      _nativeSubscriptionObserverAttached = true;
      OneSignal.User.pushSubscription.addObserver((state) {
        final id = state.current.id;
        if (id == null || id.isEmpty) return;
        if (SupabaseConfig.currentUser == null) return;
        unawaited(persistSubscriptionId(id));
      });
    }
  }

  void _onWebNotificationData(Map<String, dynamic> data) {
    _navigateToLocation(_locationFromPayload(data));
  }

  void _onNativeNotificationClicked(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    if (data == null) return;
    _navigateToLocation(_locationFromPayload(data));
  }

  String _locationFromPayload(Map<String, dynamic> data) {
    final chatId = data['chatId']?.toString();
    if (chatId != null && chatId.isNotEmpty) {
      return '/chat/$chatId';
    }
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      return route;
    }
    return '/feed';
  }

  void _navigateToLocation(String location) {
    final router = AppRouter.router;
    if (router != null) {
      router.go(location);
    } else {
      AppRouter.setPendingDeepLink(location);
    }
  }

  Future<void> syncSubscriptionForCurrentUser() async {
    if (!isConfigured) return;
    await initialize();
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    if (kIsWeb) {
      try {
        debugPrint(
          '[OneSignal Web] syncSubscriptionForCurrentUser user=${user.id}',
        );
        final id = await onesignal_bridge.onesignalWebLogin(user.id);
        if (id != null && id.isNotEmpty) {
          debugPrint(
            '[OneSignal Web] subscription id received (${id.length} chars), persisting to Supabase…',
          );
          await persistSubscriptionId(id);
        } else {
          debugPrint(
            '[OneSignal Web] no subscription id yet — allow notifications in the browser; check console [ReNomada OneSignal].',
          );
        }
      } catch (e, st) {
        debugPrint('[OneSignal Web] syncSubscriptionForCurrentUser error: $e');
        debugPrint('$st');
      }
      return;
    }

    try {
      await OneSignal.login(user.id);
      await OneSignal.Notifications.requestPermission(true);
      await OneSignal.User.pushSubscription.optIn();

      await Future<void>.delayed(const Duration(milliseconds: 500));
      var subId = OneSignal.User.pushSubscription.id;
      subId ??= await _waitForSubscriptionId();
      if (subId != null && subId.isNotEmpty) {
        await persistSubscriptionId(subId);
      } else {
        debugPrint(
          'OneSignal: subscription id not ready yet (observer will persist).',
        );
      }
    } catch (e) {
      debugPrint('syncSubscriptionForCurrentUser: $e');
    }
  }

  Future<String?> _waitForSubscriptionId() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final id = OneSignal.User.pushSubscription.id;
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  Future<void> persistSubscriptionId(String subscriptionId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    final platform = _platformLabel();
    try {
      await SupabaseConfig.from(SupabaseConstants.pushTokensTable)
          .delete()
          .eq('user_id', user.id)
          .eq('platform', platform);

      await SupabaseConfig.from(SupabaseConstants.pushTokensTable).insert({
        'user_id': user.id,
        'platform': platform,
        'token': subscriptionId,
        'is_active': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint(
        '[OneSignal] push_tokens row saved platform=$platform tokenLen=${subscriptionId.length}',
      );
    } catch (e) {
      debugPrint('[OneSignal] persistSubscriptionId failed: $e');
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'web';
    }
  }

  void onLoggedOut() {}

  Future<void> unregisterCurrentDevice() async {
    final user = SupabaseConfig.currentUser;
    if (user != null) {
      try {
        await SupabaseConfig.from(SupabaseConstants.pushTokensTable)
            .delete()
            .eq('user_id', user.id);
      } catch (e) {
        debugPrint('unregisterCurrentDevice (supabase): $e');
      }
    }
    if (!isConfigured) return;
    try {
      if (kIsWeb) {
        // Avoid calling JS logout if web init never completed (SDK not ready → internal TypeError).
        if (_initialized) {
          await onesignal_bridge.onesignalWebLogout();
        }
      } else {
        await OneSignal.logout();
      }
    } catch (e) {
      debugPrint('unregisterCurrentDevice (OneSignal): $e');
    }
  }
}
