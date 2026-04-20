import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agent_template/data/providers/supabase_provider.dart';
import 'package:agent_template/core/utils/logger.dart';

part 'analytics_service.g.dart';

final _log = AppLogger.getLogger('AnalyticsService');

/// Service for tracking analytics events across Firebase and Supabase
///
/// This service provides a unified interface for logging:
/// - AI provider usage and performance
/// - User interactions and engagement
/// - Error tracking and debugging
/// - A/B testing metrics
///
/// Events are logged to:
/// - Firebase Analytics (for user behavior and funnels)
/// - Supabase (for detailed metrics and querying)
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final SupabaseClient _supabase;

  AnalyticsService(this._supabase);

  /// Track when a user sends a message
  Future<void> logMessageSent({
    required String provider,
    required String model,
    required int messageLength,
    required bool hasAttachments,
  }) async {
    await _analytics.logEvent(
      name: 'ai_message_sent',
      parameters: {
        'provider': provider,
        'model': model,
        'message_length': messageLength,
        'has_attachments': hasAttachments
            ? 'true'
            : 'false', // Convert bool to string
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when a response is received with performance metrics
  Future<void> logResponseReceived({
    required String provider,
    required String model,
    required int responseTimeMs,
    required int inputTokens,
    required int outputTokens,
    required bool usedTools,
  }) async {
    // Log to Firebase Analytics
    // Note: Firebase Analytics only accepts String or num values, not booleans
    await _analytics.logEvent(
      name: 'ai_response_received',
      parameters: {
        'provider': provider,
        'model': model,
        'response_time_ms': responseTimeMs,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'used_tools': usedTools ? 'true' : 'false', // Convert bool to string
      },
    );

    // Also log to Supabase for detailed analysis
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _log.warning('Cannot log performance metrics: User not authenticated');
        return;
      }

      await _supabase.from('ai_performance_metrics').insert({
        'user_id': userId, // Required for RLS policy
        'provider': provider,
        'model': model,
        'latency_ms': responseTimeMs,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'used_tools': usedTools,
      });
    } catch (e) {
      // Fail silently - don't break user experience for analytics
      _log.warning('Failed to log performance metrics to Supabase: $e');
    }
  }

  /// Track errors that occur during AI interactions
  Future<void> logError({
    required String provider,
    required String errorType,
    required String errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'ai_error',
      parameters: {
        'provider': provider,
        'error_type': errorType,
        'error_message': errorMessage,
      },
    );
  }

  /// Track tool/function calls
  Future<void> logToolCall({
    required String provider,
    required String toolName,
    required bool success,
    required int executionTimeMs,
  }) async {
    await _analytics.logEvent(
      name: 'ai_tool_called',
      parameters: {
        'provider': provider,
        'tool_name': toolName,
        'success': success ? 'true' : 'false', // Convert bool to string
        'execution_time_ms': executionTimeMs,
      },
    );
  }

  /// Track conversation ratings (thumbs up/down, star ratings)
  Future<void> logConversationRated({
    required String provider,
    required String model,
    required int rating,
    String? notes,
  }) async {
    await _analytics.logEvent(
      name: 'conversation_rated',
      parameters: {
        'provider': provider,
        'model': model,
        'rating': rating,
        'has_notes': notes != null ? 'true' : 'false', // Convert bool to string
      },
    );
  }

  /// Track when users manually switch providers
  Future<void> logProviderSwitch({
    required String fromProvider,
    required String toProvider,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'provider_switched',
      parameters: {
        'from_provider': fromProvider,
        'to_provider': toProvider,
        'reason': reason,
      },
    );
  }

  /// Set user properties for segmentation in Firebase Analytics
  Future<void> setUserProperties({
    required String assignedProvider,
    required bool isPremium,
  }) async {
    await _analytics.setUserProperty(
      name: 'assigned_ai_provider',
      value: assignedProvider,
    );
    await _analytics.setUserProperty(
      name: 'is_premium',
      value: isPremium.toString(),
    );
  }
}

/// Riverpod provider for AnalyticsService
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AnalyticsService(supabase);
}
