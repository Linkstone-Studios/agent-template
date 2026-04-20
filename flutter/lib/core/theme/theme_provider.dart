import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:logging/logging.dart';

final _log = Logger('ThemeProvider');

/// Theme mode notifier to manage light/dark theme switching
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _log.info('ThemeModeNotifier.build() - initializing with ThemeMode.system');
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    _log.info('setThemeMode called: $state -> $mode');
    state = mode;
  }

  void toggleTheme() {
    final oldState = state;
    // Handle all three theme modes properly
    switch (state) {
      case ThemeMode.light:
        state = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        state = ThemeMode.light;
        break;
      case ThemeMode.system:
        // If in system mode, switch to the opposite of what system currently shows
        // For simplicity, we'll switch to dark mode first
        state = ThemeMode.dark;
        break;
    }
    _log.info('toggleTheme called: $oldState -> $state');
  }
}

/// Provider for theme mode state
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Cached light theme instance
final _lightTheme = ThemeData(
  colorScheme: LegacyColorSchemes.lightZinc().copyWith(
    primary: () => const Color(0xFF6366F1),
  ),
  radius: 0.5,
  scaling: 1.0,
);

/// Cached dark theme instance
final _darkTheme = ThemeData(
  colorScheme: LegacyColorSchemes.darkZinc().copyWith(
    primary: () => const Color(0xFF6366F1),
  ),
  radius: 0.5,
  scaling: 1.0,
);

/// Light theme configuration for shadcn_flutter
ThemeData buildShadcnLightTheme() {
  _log.info(
    'buildShadcnLightTheme: brightness=${_lightTheme.brightness}, background=${_lightTheme.colorScheme.background}',
  );
  return _lightTheme;
}

/// Dark theme configuration for shadcn_flutter
ThemeData buildShadcnDarkTheme() {
  _log.info(
    'buildShadcnDarkTheme: brightness=${_darkTheme.brightness}, background=${_darkTheme.colorScheme.background}',
  );
  return _darkTheme;
}

/// Get Material TextTheme with NotoSans font as fallback
/// This ensures icons still use their native fonts (CupertinoIcons, MaterialIcons)
material.TextTheme getMaterialTextTheme() {
  return const material.TextTheme(
    displayLarge: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    displayMedium: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    displaySmall: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    headlineLarge: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    headlineMedium: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    headlineSmall: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    titleLarge: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    titleMedium: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    titleSmall: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    bodyLarge: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    bodyMedium: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    bodySmall: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    labelLarge: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    labelMedium: material.TextStyle(fontFamilyFallback: ['NotoSans']),
    labelSmall: material.TextStyle(fontFamilyFallback: ['NotoSans']),
  );
}
