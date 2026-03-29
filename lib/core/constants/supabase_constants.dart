class SupabaseConstants {
  /// Client-safe anon key (RLS still applies). Prefer env/flavors for multi-env apps.
  static const String supabaseUrl = 'https://izyqrmpoyxnjzoqlgjoa.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6eXFybXBveXhuanpvcWxnam9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NDI1MjksImV4cCI6MjA3NDMxODUyOX0.JnRB967BxmS6l4xx29zbZzCqjGeaBimt-bfaLqDQS3k';
  
  // Table names
  static const String profilesTable = 'profiles';
  static const String itemsTable = 'items';
  static const String itemPhotosTable = 'item_photos';
  static const String interactionsTable = 'interactions';
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String pushTokensTable = 'push_tokens';
  static const String locationLogsTable = 'location_logs';
  
  // RPC Functions
  static const String feedItemsByRadiusFunction = 'feed_items_by_radius';
  /// service_role only — used by n8n, not the Flutter client.
  static const String pushRecipientsNewItemRpc = 'get_push_recipients_for_new_item';
  /// service_role only — used by n8n, not the Flutter client.
  static const String pushRecipientsChatMessageRpc =
      'get_push_recipients_for_chat_message';
  
  // Storage buckets
  static const String itemPhotosBucket = 'item-photos';
  
  // Auth providers
  static const String googleProvider = 'google';
  static const String appleProvider = 'apple';
}
