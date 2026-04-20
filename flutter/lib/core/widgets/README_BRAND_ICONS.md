# Brand Icons

Custom brand icons for social authentication providers.

## Overview

This module provides custom-painted icons for popular authentication providers like Google and Apple. These icons look much more professional than using generic Material Icons.

## Features

### Google Icon
- **Custom painted** Google "G" logo
- Uses **official Google brand colors**:
  - Blue: `#4285F4`
  - Red: `#EA4335`
  - Yellow: `#FBBC05`
  - Green: `#34A853`
- Rendered as a vector graphic using `CustomPainter`
- Scales perfectly to any size
- No external dependencies or image assets needed

### Apple Icon
- Uses Material Icons `apple` icon
- Theme-aware color support
- Consistent sizing

## Usage

### Google Icon

```dart
// Default size (24px)
BrandIcons.google()

// Custom size
BrandIcons.google(size: 20)
BrandIcons.google(size: 32)
```

### Apple Icon

```dart
// Default size (24px)
BrandIcons.apple()

// Custom size and color
BrandIcons.apple(size: 20, color: Colors.white)
BrandIcons.apple(size: 20, color: colorScheme.onSurface)
```

## Example in Button

```dart
OutlinedButton(
  onPressed: () => handleGoogleSignIn(),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      BrandIcons.google(size: 20),
      const SizedBox(width: 12),
      const Text('Continue with Google'),
    ],
  ),
)
```

## Why Custom Icons?

### Before (Material Icons)
```dart
Icon(Icons.g_mobiledata, size: 28)  // ❌ Looks terrible
```

The `g_mobiledata` icon is:
- Just a generic "G" letter
- Doesn't represent the Google brand
- Monochrome (no colors)
- Unprofessional looking

### After (Custom Painted)
```dart
BrandIcons.google(size: 20)  // ✅ Looks professional
```

The custom Google icon:
- Recognizable Google "G" logo
- Official Google brand colors
- Professional appearance
- Scales perfectly
- Vector-based (crisp at any size)

## Technical Details

### CustomPainter Implementation

The Google icon uses `CustomPainter` to draw:
1. Four colored arcs (blue, red, yellow, green)
2. White circle in the center
3. Blue horizontal bar on the right

This creates the iconic Google "G" shape with the proper colors.

### Performance

- Lightweight: No image assets to load
- Fast rendering: Uses native Canvas API
- Memory efficient: Vector-based drawing
- Cacheable: CustomPainter can be cached

## Future Enhancements

Potential additions:
- [ ] Facebook icon
- [ ] Microsoft icon
- [ ] GitHub icon
- [ ] Twitter/X icon
- [ ] LinkedIn icon
- [ ] Custom color variants
- [ ] Hover/pressed states
- [ ] Animation support

## Brand Guidelines

When using brand icons, remember:
- **Google**: Use official colors, maintain aspect ratio
- **Apple**: Typically black or white, simple and clean
- **Sizing**: Keep consistent across all social buttons
- **Spacing**: Maintain proper padding around icons

## Notes

- Icons are meant for authentication buttons
- Follow each platform's brand guidelines
- Test in both light and dark themes
- Ensure proper contrast ratios
- Keep sizes consistent (typically 20-24px in buttons)

