import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry {
  final String url;
  final String htmlContent;
  final DateTime cachedAt;
  final Duration ttl;

  CacheEntry({
    required this.url,
    required this.htmlContent,
    required this.cachedAt,
    this.ttl = const Duration(hours: 24),
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;

  Map<String, dynamic> toJson() => {
    'url': url,
    'htmlContent': htmlContent,
    'cachedAt': cachedAt.toIso8601String(),
    'ttl': ttl.inSeconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    url: json['url'] as String,
    htmlContent: json['htmlContent'] as String,
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    ttl: Duration(seconds: json['ttl'] as int? ?? 86400),
  );
}

class CacheManager {
  static const String CACHE_PREFIX = 'cache_';
  static const String CACHE_INDEX_KEY = 'cache_index';
  static const int MAX_CACHE_SIZE = 10; // Max 10 pages cached

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cleanExpiredCache();
    print('[CacheManager] Initialized');
  }

  Future<void> cachePageContent({
    required String url,
    required String htmlContent,
    Duration ttl = const Duration(hours: 24),
  }) async {
    try {
      final entry = CacheEntry(
        url: url,
        htmlContent: htmlContent,
        cachedAt: DateTime.now(),
        ttl: ttl,
      );

      final key = _getCacheKey(url);
      await _prefs?.setString(key, jsonEncode(entry.toJson()));

      await _updateCacheIndex(url);

      print('[CacheManager] Cached: $url (${htmlContent.length} bytes)');
    } catch (e) {
      print('[CacheManager] Error caching page: $e');
    }
  }

  Future<CacheEntry?> getCachedContent(String url) async {
    try {
      final key = _getCacheKey(url);
      final jsonString = _prefs?.getString(key);

      if (jsonString == null) {
        print('[CacheManager] No cache found for: $url');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final entry = CacheEntry.fromJson(json);

      if (entry.isExpired) {
        print('[CacheManager] Cache expired for: $url');
        await clearCache(url);
        return null;
      }

      print('[CacheManager] Cache hit for: $url');
      return entry;
    } catch (e) {
      print('[CacheManager] Error retrieving cache: $e');
      return null;
    }
  }

  Future<bool> isCached(String url) async {
    final entry = await getCachedContent(url);
    return entry != null && !entry.isExpired;
  }

  Future<void> clearCache(String url) async {
    try {
      final key = _getCacheKey(url);
      await _prefs?.remove(key);
      await _updateCacheIndex(url, remove: true);
      print('[CacheManager] Cache cleared for: $url');
    } catch (e) {
      print('[CacheManager] Error clearing cache: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final index = _getCacheIndex();
      for (final url in index) {
        final key = _getCacheKey(url);
        await _prefs?.remove(key);
      }
      await _prefs?.remove(CACHE_INDEX_KEY);
      print('[CacheManager] All cache cleared');
    } catch (e) {
      print('[CacheManager] Error clearing all cache: $e');
    }
  }

  Future<void> _cleanExpiredCache() async {
    try {
      final index = _getCacheIndex();
      for (final url in index) {
        final entry = await getCachedContent(url);
        if (entry == null) {
          await _updateCacheIndex(url, remove: true);
        }
      }
      print('[CacheManager] Expired cache cleaned');
    } catch (e) {
      print('[CacheManager] Error cleaning expired cache: $e');
    }
  }

  Future<void> _updateCacheIndex(String url, {bool remove = false}) async {
    try {
      var index = _getCacheIndex();

      if (remove) {
        index.remove(url);
      } else {
        if (index.contains(url)) {
          index.remove(url);
        }
        index.insert(0, url);

        if (index.length > MAX_CACHE_SIZE) {
          index = index.sublist(0, MAX_CACHE_SIZE);
        }
      }

      await _prefs?.setStringList(CACHE_INDEX_KEY, index);
    } catch (e) {
      print('[CacheManager] Error updating cache index: $e');
    }
  }

  List<String> _getCacheIndex() {
    try {
      return _prefs?.getStringList(CACHE_INDEX_KEY) ?? [];
    } catch (e) {
      print('[CacheManager] Error getting cache index: $e');
      return [];
    }
  }

  String _getCacheKey(String url) => '$CACHE_PREFIX${url.hashCode}';

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final index = _getCacheIndex();
      int totalSize = 0;

      for (final url in index) {
        final entry = await getCachedContent(url);
        if (entry != null) {
          totalSize += entry.htmlContent.length;
        }
      }

      return {
        'cachedPages': index.length,
        'totalSize': totalSize,
        'maxSize': MAX_CACHE_SIZE,
      };
    } catch (e) {
      print('[CacheManager] Error getting cache stats: $e');
      return {
        'cachedPages': 0,
        'totalSize': 0,
        'maxSize': MAX_CACHE_SIZE,
      };
    }
  }
}
