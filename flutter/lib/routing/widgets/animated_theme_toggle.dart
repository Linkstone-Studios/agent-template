import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// An animated sun/moon toggle for theme switching
/// Provides a smooth, modern animation between light and dark modes
class AnimatedThemeToggle extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const AnimatedThemeToggle({
    required this.isDark,
    required this.onTap,
    super.key,
  });

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    if (widget.isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDark != oldWidget.isDark) {
      if (widget.isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Animated icon container
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159, // 180 degrees
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.isDark
                              ? CupertinoIcons.moon_stars_fill
                              : CupertinoIcons.sun_max_fill,
                          color: widget.isDark
                              ? colorScheme.primary
                              : Colors.amber.shade700,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  widget.isDark ? 'Dark mode' : 'Light mode',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

