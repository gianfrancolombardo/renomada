import 'package:flutter/foundation.dart';
import '../../core/config/supabase_config.dart';
import 'chat_realtime_service.dart';

class RealtimeManager {
  static final RealtimeManager _instance = RealtimeManager._internal();
  factory RealtimeManager() => _instance;
  RealtimeManager._internal();

  final ChatRealtimeService _chatRealtime = ChatRealtimeService();
  bool _isInitialized = false;

  // Initialize all realtime services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if user is authenticated
      if (!SupabaseConfig.isAuthenticated) {
        debugPrint('⚠️ Cannot initialize realtime: user not authenticated');
        return;
      }

      // Initialize chat realtime
      await _chatRealtime.initialize();
      
      _isInitialized = true;
      debugPrint('✅ All realtime services initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize realtime services: $e');
    }
  }

  // Disconnect all realtime services
  Future<void> disconnect() async {
    try {
      await _chatRealtime.disconnect();
      _isInitialized = false;
      debugPrint('✅ All realtime services disconnected');
    } catch (e) {
      debugPrint('❌ Failed to disconnect realtime services: $e');
    }
  }

  // Reinitialize after login
  Future<void> reinitialize() async {
    await disconnect();
    await initialize();
  }

  bool get isInitialized => _isInitialized;
}
