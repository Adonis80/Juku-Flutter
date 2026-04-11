import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// First Master crown shower overlay (SM-3.5.5).
///
/// Shown when a player is the first to fully master a deck.
/// Crown particles instead of confetti.
class SmFirstMasterOverlay extends StatefulWidget {
  final VoidCallback? onDismiss;

  const SmFirstMasterOverlay({super.key, this.onDismiss});

  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SmFirstMasterOverlay(onDismiss: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  State<SmFirstMasterOverlay> createState() => _SmFirstMasterOverlayState();
}

class _SmFirstMasterOverlayState extends State<SmFirstMasterOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Crown> _crowns;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _crowns = List.generate(30, (_) {
      return _Crown(
        x: _rng.nextDouble(),
        dy: _rng.nextDouble() * 300 + 200,
        dx: (_rng.nextDouble() - 0.5) * 100,
        rotation: (_rng.nextDouble() - 0.5) * pi,
        size: _rng.nextDouble() * 12 + 8,
        delay: _rng.nextDouble() * 0.3,
      );
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: widget.onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Crown shower.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _CrownShowerPainter(
                    crowns: _crowns,
                    progress: _controller.value,
                  ),
                );
              },
            ),
            // Center text.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '👑',
                    style: TextStyle(fontSize: 72),
                  ).animate().scale(
                    begin: const Offset(0.0, 0.0),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                    duration: const Duration(milliseconds: 800),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "You're the First Master!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD700),
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
                  const SizedBox(height: 8),
                  const Text(
                    '+50 bonus XP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Crown {
  final double x, dy, dx, rotation, size, delay;
  const _Crown({
    required this.x,
    required this.dy,
    required this.dx,
    required this.rotation,
    required this.size,
    required this.delay,
  });
}

class _CrownShowerPainter extends CustomPainter {
  final List<_Crown> crowns;
  final double progress;
  _CrownShowerPainter({required this.crowns, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final c in crowns) {
      final t = ((progress - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = c.x * size.width + c.dx * t;
      final y = -20 + c.dy * t;
      final alpha = (255 * (1 - t * 0.5)).round().clamp(0, 255);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rotation * t);

      textPainter.text = TextSpan(
        text: '👑',
        style: TextStyle(
          fontSize: c.size,
          color: Colors.white.withAlpha(alpha),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-c.size / 2, -c.size / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CrownShowerPainter old) =>
      old.progress != progress;
}
