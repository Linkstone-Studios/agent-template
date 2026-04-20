import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

part 'conversation_analytics_repository.g.dart';

/// Repository for accessing conversation analytics views
/// Provides aggregated insights on AI provider performance and prompt effectiveness
@riverpod
ConversationAnalyticsRepository conversationAnalyticsRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return ConversationAnalyticsRepository(client);
}

// ============================================================================
// Analytics Models
// ============================================================================

/// Average rating by AI provider (Hermes vs Firebase AI)
class ProviderRatingStats {
  final String provider;
  final int ratedConversations;
  final double avgRating;
  final double? ratingStddev;
  final int minRating;
  final int maxRating;
  final int highRatingsCount;
  final int lowRatingsCount;
  final double satisfactionPercentage;
  final DateTime date;

  ProviderRatingStats({
    required this.provider,
    required this.ratedConversations,
    required this.avgRating,
    this.ratingStddev,
    required this.minRating,
    required this.maxRating,
    required this.highRatingsCount,
    required this.lowRatingsCount,
    required this.satisfactionPercentage,
    required this.date,
  });

  factory ProviderRatingStats.fromJson(Map<String, dynamic> json) {
    return ProviderRatingStats(
      provider: json['provider'] as String,
      ratedConversations: json['rated_conversations'] as int,
      avgRating: (json['avg_rating'] as num).toDouble(),
      ratingStddev: json['rating_stddev'] != null
          ? (json['rating_stddev'] as num).toDouble()
          : null,
      minRating: json['min_rating'] as int,
      maxRating: json['max_rating'] as int,
      highRatingsCount: json['high_ratings_count'] as int,
      lowRatingsCount: json['low_ratings_count'] as int,
      satisfactionPercentage: (json['satisfaction_percentage'] as num)
          .toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}

/// Average rating by prompt template
class TemplateRatingStats {
  final String templateId;
  final String templateName;
  final String? templateDescription;
  final int ratedConversations;
  final double avgRating;
  final double? ratingStddev;
  final int minRating;
  final int maxRating;
  final int highRatingsCount;
  final int lowRatingsCount;
  final double satisfactionPercentage;
  final DateTime date;

  TemplateRatingStats({
    required this.templateId,
    required this.templateName,
    this.templateDescription,
    required this.ratedConversations,
    required this.avgRating,
    this.ratingStddev,
    required this.minRating,
    required this.maxRating,
    required this.highRatingsCount,
    required this.lowRatingsCount,
    required this.satisfactionPercentage,
    required this.date,
  });

  factory TemplateRatingStats.fromJson(Map<String, dynamic> json) {
    return TemplateRatingStats(
      templateId: json['template_id'] as String,
      templateName: json['template_name'] as String,
      templateDescription: json['template_description'] as String?,
      ratedConversations: json['rated_conversations'] as int,
      avgRating: (json['avg_rating'] as num).toDouble(),
      ratingStddev: json['rating_stddev'] != null
          ? (json['rating_stddev'] as num).toDouble()
          : null,
      minRating: json['min_rating'] as int,
      maxRating: json['max_rating'] as int,
      highRatingsCount: json['high_ratings_count'] as int,
      lowRatingsCount: json['low_ratings_count'] as int,
      satisfactionPercentage: (json['satisfaction_percentage'] as num)
          .toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}

/// Prompt template usage statistics
class TemplateUsageStats {
  final String templateId;
  final String templateName;
  final String? templateDescription;
  final bool isPublic;
  final int conversationCount;
  final int uniqueUsers;
  final DateTime? lastUsedAt;
  final DateTime? firstUsedAt;
  final DateTime? date;

  TemplateUsageStats({
    required this.templateId,
    required this.templateName,
    this.templateDescription,
    required this.isPublic,
    required this.conversationCount,
    required this.uniqueUsers,
    this.lastUsedAt,
    this.firstUsedAt,
    this.date,
  });

  factory TemplateUsageStats.fromJson(Map<String, dynamic> json) {
    return TemplateUsageStats(
      templateId: json['template_id'] as String,
      templateName: json['template_name'] as String,
      templateDescription: json['template_description'] as String?,
      isPublic: json['is_public'] as bool,
      conversationCount: json['conversation_count'] as int,
      uniqueUsers: json['unique_users'] as int,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      firstUsedAt: json['first_used_at'] != null
          ? DateTime.parse(json['first_used_at'] as String)
          : null,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
    );
  }
}

/// Conversation count by provider over time
class ProviderUsageOverTime {
  final String provider;
  final String model;
  final int conversationCount;
  final int uniqueUsers;
  final int totalMessages;
  final double avgMessagesPerConversation;
  final DateTime date;
  final DateTime week;
  final DateTime month;

  ProviderUsageOverTime({
    required this.provider,
    required this.model,
    required this.conversationCount,
    required this.uniqueUsers,
    required this.totalMessages,
    required this.avgMessagesPerConversation,
    required this.date,
    required this.week,
    required this.month,
  });

  factory ProviderUsageOverTime.fromJson(Map<String, dynamic> json) {
    return ProviderUsageOverTime(
      provider: json['provider'] as String,
      model: json['model'] as String,
      conversationCount: json['conversation_count'] as int,
      uniqueUsers: json['unique_users'] as int,
      totalMessages: json['total_messages'] as int,
      avgMessagesPerConversation: (json['avg_messages_per_conversation'] as num)
          .toDouble(),
      date: DateTime.parse(json['date'] as String),
      week: DateTime.parse(json['week'] as String),
      month: DateTime.parse(json['month'] as String),
    );
  }
}

/// Provider x Template performance matrix
class ProviderTemplatePerformance {
  final String provider;
  final String model;
  final String? templateId;
  final String? templateName;
  final int conversationCount;
  final int ratingCount;
  final double? avgRating;
  final double? satisfactionPercentage;
  final double? avgMessagesPerConversation;
  final DateTime week;

  ProviderTemplatePerformance({
    required this.provider,
    required this.model,
    this.templateId,
    this.templateName,
    required this.conversationCount,
    required this.ratingCount,
    this.avgRating,
    this.satisfactionPercentage,
    this.avgMessagesPerConversation,
    required this.week,
  });

  factory ProviderTemplatePerformance.fromJson(Map<String, dynamic> json) {
    return ProviderTemplatePerformance(
      provider: json['provider'] as String,
      model: json['model'] as String,
      templateId: json['template_id'] as String?,
      templateName: json['template_name'] as String?,
      conversationCount: json['conversation_count'] as int,
      ratingCount: json['rating_count'] as int,
      avgRating: json['avg_rating'] != null
          ? (json['avg_rating'] as num).toDouble()
          : null,
      satisfactionPercentage: json['satisfaction_percentage'] != null
          ? (json['satisfaction_percentage'] as num).toDouble()
          : null,
      avgMessagesPerConversation: json['avg_messages_per_conversation'] != null
          ? (json['avg_messages_per_conversation'] as num).toDouble()
          : null,
      week: DateTime.parse(json['week'] as String),
    );
  }
}

// ============================================================================
// Repository
// ============================================================================

class ConversationAnalyticsRepository {
  final SupabaseClient _client;

  ConversationAnalyticsRepository(this._client);

  /// Get average rating by provider (daily breakdown)
  Future<List<ProviderRatingStats>> getProviderRatingStats({
    int limitDays = 30,
  }) async {
    final response = await _client
        .from('conversation_avg_rating_by_provider')
        .select()
        .gte(
          'date',
          DateTime.now().subtract(Duration(days: limitDays)).toIso8601String(),
        )
        .order('date', ascending: false);

    return (response as List)
        .map((json) => ProviderRatingStats.fromJson(json))
        .toList();
  }

  /// Get average rating by template (daily breakdown)
  Future<List<TemplateRatingStats>> getTemplateRatingStats({
    int limitDays = 30,
  }) async {
    final response = await _client
        .from('conversation_avg_rating_by_template')
        .select()
        .gte(
          'date',
          DateTime.now().subtract(Duration(days: limitDays)).toIso8601String(),
        )
        .order('date', ascending: false)
        .order('avg_rating', ascending: false);

    return (response as List)
        .map((json) => TemplateRatingStats.fromJson(json))
        .toList();
  }

  /// Get most used prompt templates
  Future<List<TemplateUsageStats>> getTemplateUsageStats() async {
    final response = await _client
        .from('prompt_template_usage_stats')
        .select()
        .order('conversation_count', ascending: false)
        .limit(20);

    return (response as List)
        .map((json) => TemplateUsageStats.fromJson(json))
        .toList();
  }

  /// Get provider usage over time
  Future<List<ProviderUsageOverTime>> getProviderUsageOverTime({
    int limitDays = 30,
  }) async {
    final response = await _client
        .from('conversation_count_by_provider_over_time')
        .select()
        .gte(
          'date',
          DateTime.now().subtract(Duration(days: limitDays)).toIso8601String(),
        )
        .order('date', ascending: false);

    return (response as List)
        .map((json) => ProviderUsageOverTime.fromJson(json))
        .toList();
  }

  /// Get provider x template performance matrix
  Future<List<ProviderTemplatePerformance>> getProviderTemplatePerformance({
    int limitWeeks = 4,
  }) async {
    final response = await _client
        .from('provider_template_performance_matrix')
        .select()
        .gte(
          'week',
          DateTime.now()
              .subtract(Duration(days: limitWeeks * 7))
              .toIso8601String(),
        )
        .order('week', ascending: false)
        .order('avg_rating', ascending: false);

    return (response as List)
        .map((json) => ProviderTemplatePerformance.fromJson(json))
        .toList();
  }
}
