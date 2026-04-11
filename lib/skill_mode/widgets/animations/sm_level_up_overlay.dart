import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/sm_xp_engine.dart';

/// Full-screen level-up celebration overlay (SM-3.2).
///
/// New level badge flies in, particle fountain, auto-dismiss 3 seconds.
class SmLevelUpOverlay extends StatefulWidget {
  final SmLevelUp levelUp;
  final VoidCallback? onDismiss;

  const SmLevelUpOverlay({super.key, required this.levelUp, this.onDismiss});

  /// Show as an overlay entry.
  static void show(BuildContext context, SmLevelUp levelUp) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          SmLevelUpOverlay(levelUp: levelUp, onDismiss: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  State<SmLevelUpOverlay> createState() => _SmLevelUpOverlayState();
}

class _SmLevelUpOverlayState extends State<SmLevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late List<_Particle> _particles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _particles = List.generate(60, (_) {
      return _Particle(
        x: _rng.nextDouble(),
        dx: (_rng.nextDouble() - 0.5) * 150,
        dy: -_rng.nextDouble() * 400 - 100,
        size: _rng.nextDouble() * 6 + 2,
        color: [
          const Color(0xFFF59E0B),
          const Color(0xFFFBBF24),
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6),
          const Color(0xFF10B981),
        ][_rng.nextInt(5)],
      );
    });

    // Auto-dismiss after 3 seconds.
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  String get _rankLabel {
    return switch (widget.levelUp.newRank) {
      'bronze' => 'Bronze',
      'silver' => 'Silver',
      'gold' => 'Gold',
      'diamond' => 'Diamond',
      'mythic' => 'Mythic',
      _ => widget.levelUp.newRank,
    };
  }

  Color get _rankColor {
    return switch (widget.levelUp.newRank) {
      'bronze' => const Color(0xFFCD7F32),
      'silver' => const Color(0xFFC0C0C0),
      'gold' => const Color(0xFFFFD700),
      'diamond' => const Color(0xFF7DF9FF),
      'mythic' => const Color(0xFF8B5CF6),
      _ => const Color(0xFFF59E0B),
    };
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
            // Particle fountain.
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                );
              },
            ),

            // Level badge.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level number badge.
                  Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [_rankColor, _rankColor.withAlpha(180)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _rankColor.withAlpha(120),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.levelUp.newLevel}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1.0, 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: const Duration(milliseconds: 200)),

                  const SizedBox(height: 24),

                  Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _rankColor,
                          letterSpacing: 4,
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 300),
                      )
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 300),
                      ),

                  const SizedBox(height: 8),

                  Text(
                    '$_rankLabel Rank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _rankColor.withAlpha(200),
                    ),
                  ).animate().fadeIn(
                    delay: const Duration(milliseconds: 700),
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double dx;
  final double dy;
  final double size;
  final Color color;

  const _Particle({
    required this.x,
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (255 * (1 - progress * 0.8)).round().clamp(0, 255);
      final paint = Paint()..color = p.color.withAlpha(alpha);
      final x = p.x * size.width + p.dx * progress;
      final y = size.height * 0.5 + p.dy * progress + 300 * progress * progress;
      canvas.drawCircle(Offset(x, y), p.size * (1 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}
