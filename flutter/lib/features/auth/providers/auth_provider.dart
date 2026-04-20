import 'dart:async';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../data/providers/supabase_provider.dart';

part 'auth_provider.g.dart';

final _log = Logger('Auth');

class AuthStateData {
  const AuthStateData({
    this.user,
    this.session,
    this.isLoading = false,
    this.error,
  });

  final supabase.User? user;
  final supabase.Session? session;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null && session != null;

  AuthStateData copyWith({
    supabase.User? user,
    supabase.Session? session,
    bool? isLoading,
    String? error,
  }) {
    return AuthStateData(
      user: user ?? this.user,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  Future<AuthStateData> build() async {
    final client = ref.watch(supabaseClientProvider);

    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        _handleAuthChange(authState);
      });
    });

    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    return AuthStateData(user: user, session: session);
  }

  void _handleAuthChange(supabase.AuthState authState) {
    final event = authState.event;
    final session = authState.session;

    _log.info('Auth state changed: $event');

    switch (event) {
      case supabase.AuthChangeEvent.signedIn:
      case supabase.AuthChangeEvent.tokenRefreshed:
      case supabase.AuthChangeEvent.initialSession:
        state = AsyncData(AuthStateData(user: session?.user, session: session));
        break;
      case supabase.AuthChangeEvent.signedOut:
        state = const AsyncData(AuthStateData());
        break;
      case supabase.AuthChangeEvent.userUpdated:
        state = AsyncData(
          state.value?.copyWith(user: session?.user, session: session) ??
              AuthStateData(user: session?.user, session: session),
        );
        break;
      default:
        break;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AsyncData(
      state.value?.copyWith(isLoading: true) ??
          const AuthStateData(isLoading: true),
    );

    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(email: email, password: password);
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;
      state = AsyncData(AuthStateData(user: user, session: session));
    } on supabase.AuthException catch (e) {
      state = AsyncData(
        state.value?.copyWith(isLoading: false, error: e.message) ??
            AuthStateData(error: e.message),
      );
      rethrow;
    } catch (e) {
      state = AsyncData(
        state.value?.copyWith(isLoading: false, error: e.toString()) ??
            AuthStateData(error: e.toString()),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = AsyncData(
      state.value?.copyWith(isLoading: true) ??
          const AuthStateData(isLoading: true),
    );

    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signOut();
      // isLoading will be reset when auth state changes to signedOut
    } catch (e) {
      _log.severe('Error signing out: $e');
      state = AsyncData(
        state.value?.copyWith(isLoading: false, error: e.toString()) ??
            AuthStateData(error: e.toString()),
      );
    }
  }
}
