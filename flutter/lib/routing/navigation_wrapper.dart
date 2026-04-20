import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import '../core/theme/theme_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../data/providers/supabase_provider.dart';
import 'app_router.dart';
import 'widgets/animated_theme_toggle.dart';

final _log = Logger('NavigationWrapper');

/// Navigation wrapper with shadcn-style sidebar
class NavigationWrapper extends ConsumerWidget {
  final Widget child;

  const NavigationWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(supabaseUserProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use themeMode directly instead of theme.brightness since shadcnApp
    // might not be properly updating Theme.of(context)
    final isDark =
        themeMode == shadcn.ThemeMode.dark ||
        (themeMode == shadcn.ThemeMode.system &&
            theme.brightness == Brightness.dark);

    _log.info(
      'NavigationWrapper build: themeMode=$themeMode, theme.brightness=${theme.brightness}, isDark=$isDark',
    );

    return Scaffold(
      body: Row(
        children: [
          // Shadcn-style sidebar
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
              border: Border(
                right: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with logo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.square_stack_3d_up,
                          size: 18,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AgentTemplate',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _NavItem(
                        icon: CupertinoIcons.house,
                        selectedIcon: CupertinoIcons.house_fill,
                        label: 'Home',
                        isSelected: currentPath == AppRoutes.home,
                        onTap: () => context.go(AppRoutes.home),
                      ),
                      const SizedBox(height: 4),
                      _NavItem(
                        icon: CupertinoIcons.chat_bubble,
                        selectedIcon: CupertinoIcons.chat_bubble_fill,
                        label: 'Chat',
                        isSelected: currentPath == AppRoutes.chat,
                        onTap: () => context.go(AppRoutes.chat),
                      ),
                      const SizedBox(height: 4),
                      _NavItem(
                        icon: CupertinoIcons.clock,
                        selectedIcon: CupertinoIcons.clock_fill,
                        label: 'Conversations',
                        isSelected: currentPath == AppRoutes.conversations,
                        onTap: () => context.go(AppRoutes.conversations),
                      ),
                    ],
                  ),
                ),
                // Bottom section with theme toggle and user
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Animated theme toggle
                      AnimatedThemeToggle(
                        isDark: isDark,
                        onTap: () {
                          _log.info('Theme toggle button clicked');
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 8),
                      // User menu
                      _UserMenu(user: user, ref: ref),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Navigation item widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User menu widget
class _UserMenu extends StatelessWidget {
  final dynamic user;
  final WidgetRef ref;

  const _UserMenu({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final isSigningOut = authState.value?.isLoading ?? false;

    return PopupMenuButton<String>(
      position: PopupMenuPosition.over,
      offset: const Offset(0, -8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      enabled: !isSigningOut,
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.email ?? 'User',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Account',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          enabled: !isSigningOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isSigningOut
              ? Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Signing out...',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_right_square,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout' && !isSigningOut) {
          ref.read(authStateProvider.notifier).signOut();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user?.email?.split('@').first ?? 'User',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.ellipsis,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
