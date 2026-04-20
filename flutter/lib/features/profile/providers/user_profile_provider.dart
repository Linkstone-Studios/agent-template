import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/providers/supabase_provider.dart';

part 'user_profile_provider.g.dart';

/// Provider for the current user's profile
/// Automatically fetches and caches the user profile based on auth state
@riverpod
Future<Users?> currentUserProfile(Ref ref) async {
  // Watch the current user from auth
  final authUser = ref.watch(supabaseUserProvider);
  
  if (authUser == null) return null;
  
  // Get the user repository
  final userRepo = ref.watch(userRepositoryProvider);
  
  // Fetch the user profile from the database
  return await userRepo.getUserById(authUser.id);
}

/// Provider for checking if a username is available
@riverpod
class UsernameChecker extends _$UsernameChecker {
  @override
  FutureOr<bool?> build() => null;

  Future<bool> check(String username) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final userRepo = ref.read(userRepositoryProvider);
      return await userRepo.isUsernameAvailable(username);
    });
    return state.value ?? false;
  }
}

