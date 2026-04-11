import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/sm_session_notifier.dart';
import 'sm_streak_flame.dart';

/// Persistent HUD overlay during sessions (SM-3.1).
///
/// - **XP Bar:** fills in real-time as orbs land
/// - **Streak Flame:** height = 24dp + (streakDays × 1.5dp), pulses at 30+
/// - **Combo Counter:** appears at 3x, bob animation, shatter on break
/// - **Session arc:** top-right, "7 of 20", subtle
class SmHud extends ConsumerStatefulWidget {
  final int streakDays;

  const SmHud({super.key, this.streakDays = 0});

  @override
  ConsumerState<SmHud> createState() => _SmHudState();
}

class _SmHudState extends ConsumerState<SmHud> with TickerProviderStateMixin {
  int _prevXp = 0;
  int _prevCombo = 0;
  bool _comboShattered = false;

  // XP bar animation.
  late AnimationController _xpBarController;
  double _xpBarFrom = 0;
  double _xpBarTo = 0;

  // Combo scale animation.
  late AnimationController _comboScaleController;

  // Combo shatter animation.
  late AnimationController _shatterController;
  List<_ShatterShard> _shards = [];

  @override
  void initState() {
    super.initState();
    _xpBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _comboScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shatterController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() => _comboShattered = false);
          }
        });
  }

  @override
  void dispose() {
    _xpBarController.dispose();
    _comboScaleController.dispose();
    _shatterController.dispose();
    super.dispose();
  }

  void _onSessionChanged(SmSessionState session) {
    // XP changed — animate bar.
    if (session.currentXp != _prevXp) {
      _xpBarFrom = _xpBarTo;
      _xpBarTo = session.currentXp.toDouble();
      _xpBarController.forward(from: 0);
      _prevXp = session.currentXp;
    }

    // Combo changed.
    if (session.combo != _prevCombo) {
      if (session.combo > _prevCombo && session.combo >= 3) {
        // Combo increased — scale pulse.
        _comboScaleController.forward(from: 0);
      } else if (session.combo == 0 && _prevCombo >= 3) {
        // Combo broken — shatter!
        _triggerShatter();
      }
      _prevCombo = session.combo;
    }
  }

  void _triggerShatter() {
    final rng = Random();
    _shards = List.generate(25, (_) {
      return _ShatterShard(
        dx: (rng.nextDouble() - 0.5) * 100,
        dy: (rng.nextDouble() - 0.5) * 100,
        rotation: rng.nextDouble() * pi * 2,
        size: rng.nextDouble() * 4 + 2,
      );
    });
    setState(() => _comboShattered = true);
    _shatterController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(smSessionProvider);
    final theme = Theme.of(context);

    // Detect changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSessionChanged(session);
    });

    final progress = session.totalCards > 0
        ? session.cardsReviewed / session.totalCards
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Session arc — progress ring.
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                Text(
                  '${session.cardsReviewed}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Streak flame.
          SmStreakFlame(streakDays: widget.streakDays),

          const Spacer(),

          // Combo counter — appears at 3x.
          if (session.combo >= 3 || _comboShattered)
            _buildCombo(session, theme),

          const SizedBox(width: 12),

          // XP bar + value.
          _buildXpBar(session, theme),
        ],
      ),
    );
  }

  Widget _buildCombo(SmSessionState session, ThemeData theme) {
    if (_comboShattered) {
      return AnimatedBuilder(
        animation: _shatterController,
        builder: (context, _) {
          return SizedBox(
            width: 48,
            height: 32,
            child: CustomPaint(
              painter: _ShatterPainter(
                shards: _shards,
                progress: _shatterController.value,
                color: const Color(0xFFF59E0B),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _comboScaleController,
      builder: (context, child) {
        // Scale pulse: 1.0 → 1.4 → 1.0.
        final t = _comboScaleController.value;
        final scale = t < 0.5 ? 1.0 + t * 0.8 : 1.4 - (t - 0.5) * 0.8;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF59E0B).withAlpha(40),
              const Color(0xFFEF4444).withAlpha(30),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B).withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 16,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 4),
            Text(
              '${session.combo}x',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 200)),
    );
  }

  Widget _buildXpBar(SmSessionState session, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // XP bar.
        SizedBox(
          width: 80,
          height: 8,
          child: AnimatedBuilder(
            animation: _xpBarController,
            builder: (context, _) {
              // Interpolate bar fill.
              final currentXp =
                  _xpBarFrom +
                  (_xpBarTo - _xpBarFrom) *
                      Curves.easeOut.transform(_xpBarController.value);
              // Normalize: assume 100 XP per session as "full".
              final fill = (currentXp / 100).clamp(0.0, 1.0);

              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(color: theme.colorScheme.surfaceContainerHighest),
                    FractionallySizedBox(
                      widthFactor: fill,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF59E0B),
                              const Color(0xFFFBBF24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        // XP value.
        const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
        const SizedBox(width: 2),
        Text(
          '${session.currentXp}',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ShatterShard {
  final double dx;
  final double dy;
  final double rotation;
  final double size;

  const _ShatterShard({
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.size,
  });
}

class _ShatterPainter extends CustomPainter {
  final List<_ShatterShard> shards;
  final double progress;
  final Color color;

  _ShatterPainter({
    required this.shards,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final alpha = (255 * (1 - progress)).round().clamp(0, 255);
    final paint = Paint()..color = color.withAlpha(alpha);

    for (final shard in shards) {
      final x = cx + shard.dx * progress;
      final y = cy + shard.dy * progress;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(shard.rotation * progress);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: shard.size,
          height: shard.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ShatterPainter old) => old.progress != progress;
}
