import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_template/features/chat/providers/ai_chat_provider.dart';

/// Entry in the tool result cache
class CacheEntry {
  final ToolResult result;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.result,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Service for caching tool execution results
///
/// Implements an LRU cache with configurable TTL per tool type.
/// Helps avoid redundant API calls and improves response time.
class ToolCacheService {
  final int _maxSize;
  final LinkedHashMap<String, CacheEntry> _cache = LinkedHashMap();

  /// Default TTL configurations by tool category
  static const Map<String, Duration> _defaultTtls = {
    'computation': Duration(hours: 1), // Deterministic, long cache
    'search': Duration(minutes: 5), // Fast-changing data
    'weather': Duration(minutes: 15), // Semi-stable data
    'database': Duration(minutes: 1), // Frequently changing
    'file_system': Duration(seconds: 30), // Frequently changing
  };

  ToolCacheService({int maxSize = 100}) : _maxSize = maxSize;

  /// Generate cache key from tool name and arguments
  String _generateKey(String toolName, Map<String, dynamic> args) {
    // Sort keys for consistent hashing
    final sortedArgs = Map.fromEntries(
      args.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final argsString = json.encode(sortedArgs);
    final combined = '$toolName:$argsString';

    // Hash to keep keys manageable
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get TTL for a tool based on its category
  Duration _getTtl(String category) {
    return _defaultTtls[category] ?? const Duration(minutes: 5);
  }

  /// Get cached result if available and not expired
  ToolResult? get(String toolName, Map<String, dynamic> args, String category) {
    final key = _generateKey(toolName, args);
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    // Move to end (LRU: most recently used)
    _cache.remove(key);
    _cache[key] = entry;

    return entry.result;
  }

  /// Cache a tool result
  void put(
    String toolName,
    Map<String, dynamic> args,
    ToolResult result,
    String category, {
    Duration? customTtl,
  }) {
    final key = _generateKey(toolName, args);
    final ttl = customTtl ?? _getTtl(category);

    // Remove oldest entry if at capacity
    if (_cache.length >= _maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    _cache[key] = CacheEntry(
      result: result,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }

  /// Clear expired entries
  void cleanExpired() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Clear all cached results
  void clear() {
    _cache.clear();
  }

  /// Clear cache for a specific tool
  void clearTool(String toolName) {
    _cache.removeWhere(
      (key, entry) => entry.result.toolName == toolName,
    );
  }

  /// Get cache statistics
  CacheStats getStats() {
    final now = DateTime.now();
    final validEntries = _cache.values.where((e) => !e.isExpired).length;
    final expiredEntries = _cache.length - validEntries;

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      maxSize: _maxSize,
    );
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int maxSize;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.maxSize,
  });

  double get fillPercentage => (totalEntries / maxSize) * 100;
}

/// Provider for the tool cache service
final toolCacheServiceProvider = Provider<ToolCacheService>((ref) {
  return ToolCacheService();
});

