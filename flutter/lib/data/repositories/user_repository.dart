import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/supabase_provider.dart';

part 'user_repository.g.dart';

/// Repository for user profile data
/// Provides type-safe access to the users table
@riverpod
UserRepository userRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserRepository(client);
}

class UserRepository {
  final SupabaseClient _client;

  UserRepository(this._client);

  /// Get a user by ID
  Future<Users?> getUserById(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Users.fromJson(response as Map<String, dynamic>);
  }

  /// Get a user by email
  Future<Users?> getUserByEmail(String email) async {
    final response = await _client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) return null;
    return Users.fromJson(response as Map<String, dynamic>);
  }

  /// Get a user by username
  Future<Users?> getUserByUsername(String username) async {
    final response = await _client
        .from('users')
        .select()
        .eq('username', username)
        .maybeSingle();

    if (response == null) return null;
    return Users.fromJson(response as Map<String, dynamic>);
  }

  /// Create a new user profile
  Future<Users> createUser({
    required String id,
    required String email,
    required String username,
    String? fullName,
    String? avatarUrl,
  }) async {
    final user = Users(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _client.from('users').insert(user.toJson());
    return user;
  }

  /// Update a user's profile
  Future<Users> updateUser(Users user) async {
    final updatedUser = user.copyWith(updatedAt: DateTime.now());

    await _client.from('users').update(updatedUser.toJson()).eq('id', user.id);

    return updatedUser;
  }

  /// Update specific user fields
  Future<void> updateUserFields(
    String userId, {
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (username != null) updates['username'] = username;
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('users').update(updates).eq('id', userId);
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    await _client.from('users').delete().eq('id', userId);
  }

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _client
        .from('users')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    return response == null;
  }

  /// Check if an email is already registered
  Future<bool> isEmailRegistered(String email) async {
    final response = await _client
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();

    return response != null;
  }
}
