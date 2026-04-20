# Project Theming & Navigation

Complete theming system with light/dark mode support and navigation wrapper.

## Features

### 🎨 Full Theming Support
- **Light Mode**: Clean, modern light theme with Indigo accent
- **Dark Mode**: Beautiful dark theme with consistent colors
- **Material Design 3**: Uses the latest Material Design principles
- **Theme Toggle**: Easy switching between light and dark modes
- **System Theme**: Automatically follows system preferences

### 🧭 Navigation
- **Navigation Rail**: Collapsible sidebar navigation
- **Persistent Layout**: Navigation persists across all authenticated screens
- **Go Router**: Declarative routing with automatic redirects
- **Protected Routes**: Authentication-based route protection

### 🎯 Routes

| Route | Path | Description |
|-------|------|-------------|
| Login | `/login` | Authentication screen (no navigation wrapper) |
| Home | `/` | Welcome screen with quick actions |
| Chat | `/chat` | Hermes AI chat interface |

## Project Structure

```
lib/
├── core/
│   └── theme/
│       └── theme_provider.dart      # Theme configuration & provider
├── routing/
│   ├── app_router.dart              # Route definitions & auth redirect
│   └── navigation_wrapper.dart      # Navigation rail with theme toggle
└── features/
    ├── home/
    │   └── screens/
    │       └── home_screen.dart     # Home page with quick actions
    ├── chat/
    │   └── screens/
    │       └── chat_screen.dart     # AI chat interface
    └── auth/
        └── screens/
            └── login_screen.dart    # Login page
```

## Theme Configuration

### Colors

#### Light Theme
- **Primary**: Indigo (`#6366F1`)
- **Background**: Off-white (`#FAFAFA`)
- **Surface**: White

#### Dark Theme
- **Primary**: Indigo (`#6366F1`)
- **Background**: Near-black (`#09090B`)
- **Surface**: Dark gray

### Components

All Material Design 3 components are styled:
- Cards with rounded corners (12px radius)
- Elevated buttons with no elevation
- Input fields with rounded borders (8px radius)
- Consistent padding and spacing

## Usage

### Toggle Theme

The theme can be toggled from the navigation rail:
- Click the sun/moon icon in the bottom section
- Automatically saves preference (when persistence is added)

### Navigate Between Screens

1. **Using the Navigation Rail**
   - Click on Home or Chat icons

2. **Programmatically**
   ```dart
   context.go(AppRoutes.chat);
   // or
   context.go(AppRoutes.home);
   ```

### Access Current Theme

```dart
final themeMode = ref.watch(themeModeProvider);
```

### Change Theme Programmatically

```dart
// Toggle between light and dark
ref.read(themeModeProvider.notifier).toggleTheme();

// Set specific theme
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
```

## Customization

### Adding New Colors

Edit `lib/core/theme/theme_provider.dart`:

```dart
ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1), // Change this color
    brightness: Brightness.light,
  );
  // ...
}
```

### Adding New Routes

1. Add route constant in `lib/routing/app_router.dart`:
```dart
class AppRoutes {
  static const String myNewRoute = '/my-route';
}
```

2. Add route definition:
```dart
GoRoute(
  path: AppRoutes.myNewRoute,
  pageBuilder: (context, state) => NoTransitionPage(
    key: state.pageKey,
    child: const MyNewScreen(),
  ),
),
```

3. Add navigation rail destination (if needed):
```dart
NavigationRailDestination(
  icon: Icon(Icons.my_icon_outlined),
  selectedIcon: Icon(Icons.my_icon),
  label: Text('My Screen'),
),
```

## Next Steps

- [ ] Add theme persistence with SharedPreferences
- [ ] Add more color schemes (e.g., purple, green, orange)
- [ ] Add font customization
- [ ] Add animation preferences
- [ ] Create settings screen for theme customization

## Learn More

- [Material Design 3](https://m3.material.io/)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Riverpod Documentation](https://riverpod.dev/)

