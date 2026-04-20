import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/loading_phrases.dart';

/// Custom loading indicator for AI chat responses
///
/// Displays a shimmer effect with rotating medical-themed phrases
/// to indicate that the AI is processing a response.
class AiLoadingIndicator extends StatefulWidget {
  /// Custom phrase to display (if null, uses rotating phrases)
  final String? customPhrase;

  /// Duration between phrase rotations (default 5 seconds)
  final Duration rotationDuration;

  /// Text style for the loading phrase
  final TextStyle? textStyle;

  const AiLoadingIndicator({
    super.key,
    this.customPhrase,
    this.rotationDuration = const Duration(seconds: 5),
    this.textStyle,
  });

  @override
  State<AiLoadingIndicator> createState() => _AiLoadingIndicatorState();
}

class _AiLoadingIndicatorState extends State<AiLoadingIndicator> {
  late String _currentPhrase;
  Timer? _rotationTimer;
  int _phraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPhrase = widget.customPhrase ?? LoadingPhrases.getRandom();

    // Only rotate phrases if no custom phrase is provided
    if (widget.customPhrase == null) {
      _startPhraseRotation();
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startPhraseRotation() {
    _rotationTimer = Timer.periodic(widget.rotationDuration, (timer) {
      if (mounted) {
        setState(() {
          _phraseIndex++;
          _currentPhrase = LoadingPhrases.getByIndex(_phraseIndex);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Shimmer colors - use distinct base and highlight for visible animation
    final baseColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.2)
        : colorScheme.primary.withValues(alpha: 0.3);

    final highlightColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.9)
        : colorScheme.primary.withValues(alpha: 1.0);

    final textStyle =
        widget.textStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shimmer animated dots with wave effect
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(
            milliseconds: 1200,
          ), // Faster, smoother shimmer
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(colorScheme),
              const SizedBox(width: 6),
              _buildDot(colorScheme),
              const SizedBox(width: 6),
              _buildDot(colorScheme),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Rotating phrase with shimmer effect
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Shimmer.fromColors(
              key: ValueKey(_currentPhrase),
              baseColor: colorScheme.onSurface.withValues(alpha: 0.4),
              highlightColor: colorScheme.onSurface.withValues(alpha: 0.8),
              period: const Duration(milliseconds: 1500),
              child: Text(
                _currentPhrase,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(ColorScheme colorScheme) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
