import 'dart:math';

import 'package:flutter/material.dart';

/// SVG-style streak flame that grows with streak days (SM-3.1).
///
/// Height = 24dp + (streakDays × 1.5dp), max at 30 days then pulses.
/// Colour shifts orange → red as streak grows.
class SmStreakFlame extends StatefulWidget {
  final int streakDays;

  const SmStreakFlame({super.key, this.streakDays = 0});

  @override
  State<SmStreakFlame> createState() => _SmStreakFlameState();
}

class _SmStreakFlameState extends State<SmStreakFlame>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.streakDays >= 30) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SmStreakFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakDays >= 30 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.streakDays < 30 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streakDays <= 0) return const SizedBox.shrink();

    final height = 24.0 + (min(widget.streakDays, 30) * 1.5);
    final t = (widget.streakDays / 30).clamp(0.0, 1.0);
    final color = Color.lerp(
      const Color(0xFFF97316), // orange
      const Color(0xFFEF4444), // red
      t,
    )!;

    Widget flame = CustomPaint(
      size: Size(height * 0.6, height),
      painter: _FlamePainter(color: color, intensity: t),
    );

    if (widget.streakDays >= 30) {
      flame = AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + _pulseController.value * 0.1;
          return Transform.scale(scale: scale, child: child);
        },
        child: flame,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        flame,
        const SizedBox(height: 2),
        Text(
          '${widget.streakDays}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FlamePainter extends CustomPainter {
  final Color color;
  final double intensity;

  _FlamePainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer flame.
    final outerPath = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w * 0.9, h * 0.3, w * 0.8, h * 0.6)
      ..quadraticBezierTo(w * 0.7, h * 0.85, w * 0.5, h)
      ..quadraticBezierTo(w * 0.3, h * 0.85, w * 0.2, h * 0.6)
      ..quadraticBezierTo(w * 0.1, h * 0.3, w * 0.5, 0)
      ..close();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withAlpha(200),
          color,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(outerPath, outerPaint);

    // Inner bright core.
    final innerPath = Path()
      ..moveTo(w * 0.5, h * 0.25)
      ..quadraticBezierTo(w * 0.7, h * 0.45, w * 0.65, h * 0.65)
      ..quadraticBezierTo(w * 0.6, h * 0.8, w * 0.5, h * 0.9)
      ..quadraticBezierTo(w * 0.4, h * 0.8, w * 0.35, h * 0.65)
      ..quadraticBezierTo(w * 0.3, h * 0.45, w * 0.5, h * 0.25)
      ..close();

    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFF7ED),
          Color.lerp(const Color(0xFFFBBF24), color, 0.5)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) =>
      old.color != color || old.intensity != intensity;
}
