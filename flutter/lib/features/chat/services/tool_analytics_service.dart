import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agent_template/features/chat/providers/ai_chat_provider.dart';

/// Service for tracking and analyzing tool execution metrics
///
/// Logs all tool executions to Supabase for analytics and debugging.
/// Provides methods to query usage statistics and performance metrics.
class ToolAnalyticsService {
  final SupabaseClient _supabase;

  ToolAnalyticsService(this._supabase);

  /// Log a tool execution to the database
  Future<void> logExecution({
    required String toolName,
    required String category,
    required Map<String, dynamic> args,
    required int executionTimeMs,
    required bool success,
    required bool cached,
    required String provider,
    String? sessionId,
    String? errorMessage,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // Don't log if user is not authenticated
        return;
      }

      // Hash arguments for privacy (don't store actual values)
      final argsHash = _hashArgs(args);

      await _supabase.from('tool_executions').insert({
        'user_id': userId,
        'session_id': sessionId,
        'tool_name': toolName,
        'category': category,
        'args_hash': argsHash,
        'execution_time_ms': executionTimeMs,
        'success': success,
        'error_message': errorMessage,
        'cached': cached,
        'provider': provider,
      });
    } catch (e) {
      // Silently fail - don't interrupt user flow for analytics
      print('Failed to log tool execution: $e');
    }
  }

  /// Get tool usage statistics for the current user
  Future<ToolUsageStats> getUserStats({DateTime? since}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return ToolUsageStats.empty();
      }

      var query = _supabase
          .from('tool_executions')
          .select()
          .eq('user_id', userId);

      if (since != null) {
        query = query.gte('created_at', since.toIso8601String());
      }

      final data = await query;

      return _calculateStats(data as List);
    } catch (e) {
      print('Failed to fetch user stats: $e');
      return ToolUsageStats.empty();
    }
  }

  /// Get most frequently used tools for the current user
  Future<List<ToolUsageSummary>> getMostUsedTools({
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      // Note: This is a simplified version. For production, use a Supabase function
      // with GROUP BY for better performance
      var query = _supabase
          .from('tool_executions')
          .select()
          .eq('user_id', userId);

      if (since != null) {
        query = query.gte('created_at', since.toIso8601String());
      }

      final data = await query;
      final executions = data as List;

      // Group by tool name
      final Map<String, List<dynamic>> grouped = {};
      for (final exec in executions) {
        final toolName = exec['tool_name'] as String;
        grouped.putIfAbsent(toolName, () => []).add(exec);
      }

      // Calculate summaries
      final summaries = grouped.entries.map((entry) {
        final execs = entry.value;
        final successCount = execs.where((e) => e['success'] == true).length;
        final avgTime =
            execs
                .map((e) => e['execution_time_ms'] as int)
                .reduce((a, b) => a + b) /
            execs.length;

        return ToolUsageSummary(
          toolName: entry.key,
          count: execs.length,
          successRate: successCount / execs.length,
          avgExecutionTimeMs: avgTime.round(),
        );
      }).toList();

      // Sort by count descending
      summaries.sort((a, b) => b.count.compareTo(a.count));

      return summaries.take(limit).toList();
    } catch (e) {
      print('Failed to fetch most used tools: $e');
      return [];
    }
  }

  /// Hash arguments for privacy
  String _hashArgs(Map<String, dynamic> args) {
    final sortedArgs = Map.fromEntries(
      args.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final argsString = json.encode(sortedArgs);
    final bytes = utf8.encode(argsString);
    return sha256.convert(bytes).toString();
  }

  /// Calculate statistics from execution data
  ToolUsageStats _calculateStats(List executions) {
    if (executions.isEmpty) {
      return ToolUsageStats.empty();
    }

    final totalExecutions = executions.length;
    final successCount = executions.where((e) => e['success'] == true).length;
    final cachedCount = executions.where((e) => e['cached'] == true).length;

    final executionTimes = executions
        .map((e) => e['execution_time_ms'] as int)
        .toList();
    final avgExecutionTime =
        executionTimes.reduce((a, b) => a + b) / totalExecutions;

    return ToolUsageStats(
      totalExecutions: totalExecutions,
      successRate: successCount / totalExecutions,
      cacheHitRate: cachedCount / totalExecutions,
      avgExecutionTimeMs: avgExecutionTime.round(),
    );
  }
}

/// Tool usage statistics
class ToolUsageStats {
  final int totalExecutions;
  final double successRate;
  final double cacheHitRate;
  final int avgExecutionTimeMs;

  ToolUsageStats({
    required this.totalExecutions,
    required this.successRate,
    required this.cacheHitRate,
    required this.avgExecutionTimeMs,
  });

  factory ToolUsageStats.empty() {
    return ToolUsageStats(
      totalExecutions: 0,
      successRate: 0,
      cacheHitRate: 0,
      avgExecutionTimeMs: 0,
    );
  }
}

/// Summary of tool usage
class ToolUsageSummary {
  final String toolName;
  final int count;
  final double successRate;
  final int avgExecutionTimeMs;

  ToolUsageSummary({
    required this.toolName,
    required this.count,
    required this.successRate,
    required this.avgExecutionTimeMs,
  });
}

/// Provider for tool analytics service
final toolAnalyticsServiceProvider = Provider<ToolAnalyticsService>((ref) {
  final supabase = Supabase.instance.client;
  return ToolAnalyticsService(supabase);
});
