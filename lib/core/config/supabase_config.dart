import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseConfig {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _client!;
  }
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
      debug: true, // Remove in production
    );
    
    _client = Supabase.instance.client;
  }
  
  // Auth helpers
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isAuthenticated => currentUser != null;
  
  // Database helpers
  static SupabaseQueryBuilder from(String table) => client.from(table);
  static Future<dynamic> rpc(String function, [Map<String, dynamic>? params]) {
    return client.rpc(function, params: params);
  }
  
  // Storage helpers
  static SupabaseStorageClient get storage => client.storage;
  
  // Realtime helpers
  static RealtimeChannel channel(String name) => client.channel(name);
}
