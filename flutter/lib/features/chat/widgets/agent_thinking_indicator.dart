import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../utils/loading_phrases.dart';

/// Custom animated thinking indicator for our AI agent system
///
/// Features a pulsing neural network-style animation with flowing particles
/// to represent the AI processing thoughts, along with rotating medical-themed
/// loading phrases
class AgentThinkingIndicator extends StatefulWidget {
  final String? message;
  final Color? color;

  const AgentThinkingIndicator({super.key, this.message, this.color});

  @override
  State<AgentThinkingIndicator> createState() => _AgentThinkingIndicatorState();
}

class _AgentThinkingIndicatorState extends State<AgentThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  Timer? _phraseTimer;
  String _currentPhrase = LoadingPhrases.getRandom();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
      value: 1.0,
    );

    // Start phrase rotation timer (change phrase every 4 seconds)
    _phraseTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _rotatePhrase(),
    );
  }

  void _rotatePhrase() async {
    // Fade out
    await _fadeController.reverse();

    // Change phrase while invisible
    if (mounted) {
      setState(() {
        _currentPhrase = LoadingPhrases.getRandom();
      });

      // Fade in
      await _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _controller.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = widget.color ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Animated thinking visualization
          SizedBox(
            width: 40,
            height: 40,
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _pulseController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _ThinkingPainter(
                    progress: _controller.value,
                    pulse: _pulseController.value,
                    color: color,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Animated text with fade transitions
          Expanded(
            child: FadeTransition(
              opacity: _fadeController,
              child: Text(
                widget.message ?? _currentPhrase,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for neural network-style thinking animation
class _ThinkingPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final Color color;

  _ThinkingPainter({
    required this.progress,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.3 + (pulse * 0.4));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw pulsing outer circle
    canvas.drawCircle(
      center,
      radius * (0.8 + pulse * 0.2),
      paint..color = color.withValues(alpha: 0.1 + (pulse * 0.15)),
    );

    // Draw rotating particles (neural network nodes)
    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    for (int i = 0; i < 3; i++) {
      final angle = (progress * 2 * math.pi) + (i * 2 * math.pi / 3);
      final particleRadius = radius * 0.6;
      final x = center.dx + math.cos(angle) * particleRadius;
      final y = center.dy + math.sin(angle) * particleRadius;

      canvas.drawCircle(
        Offset(x, y),
        3 + pulse * 2,
        particlePaint..color = color.withValues(alpha: 0.7 + pulse * 0.3),
      );
    }

    // Draw center core
    canvas.drawCircle(center, 4 + pulse * 2, particlePaint..color = color);
  }

  @override
  bool shouldRepaint(_ThinkingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}
