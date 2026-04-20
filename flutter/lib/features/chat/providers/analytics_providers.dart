import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/repositories/conversation_analytics_repository.dart';

part 'analytics_providers.g.dart';

// ============================================================================
// Analytics Data Providers
// ============================================================================

/// Fetch provider rating statistics (last 30 days)
/// 
/// Shows which AI provider (Hermes vs Firebase AI) performs best based on
/// user ratings. Use this to identify the most effective provider for medical
/// AI tasks.
@riverpod
Future<List<ProviderRatingStats>> providerRatingStats(
  Ref ref, {
  int limitDays = 30,
}) async {
  final repository = ref.watch(conversationAnalyticsRepositoryProvider);
  return repository.getProviderRatingStats(limitDays: limitDays);
}

/// Fetch template rating statistics (last 30 days)
/// 
/// Shows which prompt templates produce the highest quality conversations.
/// Use this to optimize prompts for question generation, item critique, etc.
@riverpod
Future<List<TemplateRatingStats>> templateRatingStats(
  Ref ref, {
  int limitDays = 30,
}) async {
  final repository = ref.watch(conversationAnalyticsRepositoryProvider);
  return repository.getTemplateRatingStats(limitDays: limitDays);
}

/// Fetch template usage statistics
/// 
/// Shows which prompt templates are most popular. Helps identify which
/// templates to invest in improving and which to deprecate.
@riverpod
Future<List<TemplateUsageStats>> templateUsageStats(Ref ref) async {
  final repository = ref.watch(conversationAnalyticsRepositoryProvider);
  return repository.getTemplateUsageStats();
}

/// Fetch provider usage over time (last 30 days)
/// 
/// Time series data showing conversation volume by provider and model.
/// Use for capacity planning and identifying usage trends.
@riverpod
Future<List<ProviderUsageOverTime>> providerUsageOverTime(
  Ref ref, {
  int limitDays = 30,
}) async {
  final repository = ref.watch(conversationAnalyticsRepositoryProvider);
  return repository.getProviderUsageOverTime(limitDays: limitDays);
}

/// Fetch provider x template performance matrix (last 4 weeks)
/// 
/// Cross-tabulation showing which provider works best with which template.
/// Example: "Hermes performs better with Question Generation template,
/// but Firebase AI performs better with Item Critique template."
@riverpod
Future<List<ProviderTemplatePerformance>> providerTemplatePerformance(
  Ref ref, {
  int limitWeeks = 4,
}) async {
  final repository = ref.watch(conversationAnalyticsRepositoryProvider);
  return repository.getProviderTemplatePerformance(limitWeeks: limitWeeks);
}

// ============================================================================
// Computed Providers
// ============================================================================

/// Get the best performing provider overall
/// 
/// Returns the provider with the highest average rating across all conversations.
@riverpod
Future<String?> bestPerformingProvider(Ref ref) async {
  final stats = await ref.watch(providerRatingStatsProvider(limitDays: 30).future);
  
  if (stats.isEmpty) return null;
  
  // Group by provider and calculate overall average
  final providerAverages = <String, double>{};
  for (final stat in stats) {
    providerAverages[stat.provider] = 
        (providerAverages[stat.provider] ?? 0) + stat.avgRating;
  }
  
  // Find provider with highest average
  String? bestProvider;
  double highestAvg = 0;
  providerAverages.forEach((provider, avg) {
    if (avg > highestAvg) {
      highestAvg = avg;
      bestProvider = provider;
    }
  });
  
  return bestProvider;
}

/// Get the most effective prompt template
/// 
/// Returns the template with the highest average rating and significant usage.
@riverpod
Future<String?> mostEffectiveTemplate(Ref ref) async {
  final stats = await ref.watch(templateRatingStatsProvider(limitDays: 30).future);
  
  if (stats.isEmpty) return null;
  
  // Filter templates with at least 3 ratings (statistical significance)
  final significantTemplates = stats.where((s) => s.ratedConversations >= 3).toList();
  
  if (significantTemplates.isEmpty) return null;
  
  // Sort by average rating
  significantTemplates.sort((a, b) => b.avgRating.compareTo(a.avgRating));
  
  return significantTemplates.first.templateName;
}

/// Get overall satisfaction rate
/// 
/// Returns the percentage of conversations rated 4-5 stars across all providers.
@riverpod
Future<double> overallSatisfactionRate(Ref ref) async {
  final stats = await ref.watch(providerRatingStatsProvider(limitDays: 30).future);
  
  if (stats.isEmpty) return 0.0;
  
  int totalHighRatings = 0;
  int totalRatings = 0;
  
  for (final stat in stats) {
    totalHighRatings += stat.highRatingsCount;
    totalRatings += stat.ratedConversations;
  }
  
  if (totalRatings == 0) return 0.0;
  
  return (totalHighRatings / totalRatings) * 100;
}

