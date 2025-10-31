/// Cache for signed URLs to avoid repeated API calls
/// URLs expire 60 seconds before their actual expiry to ensure freshness
class SignedUrlCache {
  static final SignedUrlCache _instance = SignedUrlCache._internal();
  factory SignedUrlCache() => _instance;
  SignedUrlCache._internal();

  final Map<String, _CachedUrl> _cache = {};
  
  /// Get cached signed URL if available and not expired
  String? getCachedUrl(String path) {
    final cached = _cache[path];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }
    // Remove expired entry
    if (cached != null && cached.isExpired) {
      _cache.remove(path);
    }
    return null;
  }

  /// Cache a signed URL
  /// [expiresIn] is the expiry time in seconds from Supabase (typically 3600)
  void cacheUrl(String path, String url, int expiresIn) {
    // Cache with 60 second buffer before actual expiry
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
    _cache[path] = _CachedUrl(url, expiresAt);
  }

  /// Clear all cached URLs
  void clear() {
    _cache.clear();
  }

  /// Clear expired cache entries
  void clearExpired() {
    _cache.removeWhere((key, value) => value.isExpired);
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final expired = _cache.values.where((v) => v.expiresAt.isBefore(now)).length;
    return {
      'total_entries': _cache.length,
      'expired_entries': expired,
      'valid_entries': _cache.length - expired,
    };
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl(this.url, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

