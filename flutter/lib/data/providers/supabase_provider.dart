import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

@riverpod
Session? supabaseSession(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentSession;
}

@riverpod
User? supabaseUser(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
}

@riverpod
Stream<AuthState> authStateChanges(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}
