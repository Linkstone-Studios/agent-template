import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/providers/supabase_provider.dart';

part 'subscription_provider.g.dart';

/// Provider for the current user's subscription
@riverpod
Future<Subscriptions?> currentSubscription(Ref ref) async {
  final authUser = ref.watch(supabaseUserProvider);
  
  if (authUser == null) return null;
  
  final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);
  return await subscriptionRepo.getUserSubscription(authUser.id);
}

/// Provider to check if the current user has an active subscription
@riverpod
Future<bool> hasActiveSubscription(Ref ref) async {
  final authUser = ref.watch(supabaseUserProvider);
  
  if (authUser == null) return false;
  
  final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);
  return await subscriptionRepo.hasActiveSubscription(authUser.id);
}

/// Provider for subscription history
@riverpod
Future<List<Subscriptions>> subscriptionHistory(Ref ref) async {
  final authUser = ref.watch(supabaseUserProvider);
  
  if (authUser == null) return [];
  
  final subscriptionRepo = ref.watch(subscriptionRepositoryProvider);
  return await subscriptionRepo.getUserSubscriptionHistory(authUser.id);
}

