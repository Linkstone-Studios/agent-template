import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/ai_usage_repository.dart';
import '../../../data/providers/supabase_provider.dart';

part 'usage_stats_provider.g.dart';

/// Provider for the current user's AI usage statistics
/// Shows total costs, token usage, and provider breakdown
@riverpod
Future<UsageStats?> currentUserUsageStats(Ref ref) async {
  // Watch the current user from auth
  final authUser = ref.watch(supabaseUserProvider);
  
  if (authUser == null) return null;
  
  // Get the AI usage repository
  final usageRepo = ref.watch(aiUsageRepositoryProvider);
  
  // Fetch usage stats
  return await usageRepo.getUserStats(authUser.id);
}

/// Provider for the current user's recent AI usage logs
@riverpod
Future<List<AiUsageLogs>> recentUsageLogs(Ref ref) async {
  // Watch the current user from auth
  final authUser = ref.watch(supabaseUserProvider);
  
  if (authUser == null) return [];
  
  // Get the AI usage repository
  final usageRepo = ref.watch(aiUsageRepositoryProvider);
  
  // Fetch recent logs (limited to latest 50)
  final logs = await usageRepo.getUserLogs(authUser.id);
  return logs.take(50).toList();
}

/// Provider for usage logs filtered by provider
@riverpod
class ProviderUsageLogs extends _$ProviderUsageLogs {
  @override
  Future<List<AiUsageLogs>> build(AiProvider provider) async {
    final authUser = ref.watch(supabaseUserProvider);
    
    if (authUser == null) return [];
    
    final usageRepo = ref.watch(aiUsageRepositoryProvider);
    return await usageRepo.getUserLogsByProvider(authUser.id, provider);
  }
}

/// Provider for usage logs within a date range
@riverpod
Future<List<AiUsageLogs>> usageLogsByDateRange(
  Ref ref,
  DateTime startDate,
  DateTime endDate,
) async {
  final authUser = ref.watch(supabaseUserProvider);
  
  if (authUser == null) return [];
  
  final usageRepo = ref.watch(aiUsageRepositoryProvider);
  return await usageRepo.getLogsByDateRange(authUser.id, startDate, endDate);
}

