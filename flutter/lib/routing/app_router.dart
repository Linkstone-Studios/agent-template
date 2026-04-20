import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/chat/screens/conversation_list_screen.dart';
import '../features/home/screens/home_screen.dart';
import 'navigation_wrapper.dart';

/// Route names
class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String chat = '/chat';
  static const String conversations = '/conversations';
}

/// Notifier that triggers GoRouter refresh when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this._ref) {
    _ref.listen<AsyncValue<AuthStateData>>(
      authStateProvider,
      (_, next) => notifyListeners(),
    );
  }

  final Ref _ref;
}

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final notifier = GoRouterRefreshStream(ref);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Get auth state value directly
      final auth = authState.value;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final isGoingToLogin = state.matchedLocation == AppRoutes.login;

      // Redirect to login if not authenticated and not already going there
      if (!isAuthenticated && !isGoingToLogin) {
        return AppRoutes.login;
      }

      // Redirect to home if authenticated and going to login
      if (isAuthenticated && isGoingToLogin) {
        return AppRoutes.home;
      }

      return null; // No redirect needed
    },
    routes: [
      // Login route (no navigation wrapper)
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),

      // Wrapped routes (with navigation)
      ShellRoute(
        builder: (context, state, child) {
          return NavigationWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const ChatScreen()),
          ),
          GoRoute(
            path: AppRoutes.conversations,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ConversationListScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
