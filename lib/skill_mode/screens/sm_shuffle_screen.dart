import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../models/sm_card.dart';
import '../state/sm_session_notifier.dart';
import '../widgets/tile/sm_tile_widget.dart';

/// Shuffle puzzle — drag tiles to correct foreign word order (SM-2.1).
///
/// Tiles start scrambled. Long-press to lift, drag to reposition.
/// Correct order triggers celebration: magnetic snap, confetti, gold glow, XP orbs.
/// Wrong order: tiles wiggle.
class SmShuffleScreen extends ConsumerStatefulWidget {
  final String cardId;
  const SmShuffleScreen({super.key, required this.cardId});

  @override
  ConsumerState<SmShuffleScreen> createState() => _SmShuffleScreenState();
}

class _SmShuffleScreenState extends ConsumerState<SmShuffleScreen>
    with TickerProviderStateMixin {
  SmCard? _card;
  bool _loading = true;
  bool _solved = false;

  /// Current tile order — indices into the original tiles list.
  List<int> _currentOrder = [];

  /// The correct foreign word order.
  List<int> _correctOrder = [];

  /// Controllers for wrong-answer wiggle.
  final List<AnimationController> _wiggleControllers = [];

  /// Controller for the gold glow on solve.
  late AnimationController _glowController;

  /// Controller for confetti.
  late AnimationController _confettiController;

  /// Confetti particles.
  List<_ConfettiParticle> _confettiParticles = [];

  /// XP orbs for fly-to-HUD animation.
  List<_XpOrb> _xpOrbs = [];
  late AnimationController _xpOrbController;

  /// Snap stagger controllers.
  final List<AnimationController> _snapControllers = [];

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _xpOrbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadCard();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _confettiController.dispose();
    _xpOrbController.dispose();
    for (final c in _wiggleControllers) {
      c.dispose();
    }
    for (final c in _snapControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCard() async {
    try {
      final data = await supabase
          .from('skill_mode_cards')
          .select()
          .eq('id', widget.cardId)
          .single();

      if (!mounted) return;
      final card = SmCard.fromJson(data);
      final tileCount = card.sentenceTiles?.length ?? 0;

      _correctOrder =
          card.foreignWordOrder ?? List.generate(tileCount, (i) => i);

      // Scramble: shuffle until different from correct order.
      _currentOrder = List.generate(tileCount, (i) => i);
      do {
        _currentOrder.shuffle(_random);
      } while (tileCount > 1 &&
          _listEquals(_currentOrder, _correctOrder));

      // Create wiggle controllers.
      for (var i = 0; i < tileCount; i++) {
        _wiggleControllers.add(AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        ));
        _snapControllers.add(AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ));
      }

      setState(() {
        _card = card;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_solved) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
    HapticFeedback.lightImpact();
    _checkSolution();
  }

  void _checkSolution() {
    if (_listEquals(_currentOrder, _correctOrder)) {
      _onSolved();
    }
  }

  Future<void> _onSolved() async {
    setState(() => _solved = true);
    HapticFeedback.heavyImpact();

    // Sequential magnetic snap with 80ms stagger.
    for (var i = 0; i < _snapControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        _snapControllers[i].forward();
        HapticFeedback.mediumImpact();
      }
    }

    // Confetti burst.
    _generateConfetti();
    _confettiController.forward();

    // Gold glow.
    _glowController.forward();

    // XP orbs.
    _generateXpOrbs();
    _xpOrbController.forward();

    // Award XP.
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(smSessionProvider.notifier).addXp(10);
      ref.read(smSessionProvider.notifier).incrementCombo();
      _awardXp(user.id, 10);
    }

    // Auto-advance after celebration.
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      ref.read(smSessionProvider.notifier).advanceCard();
      context.pop();
    }
  }

  void _triggerWiggle() {
    HapticFeedback.lightImpact();
    ref.read(smSessionProvider.notifier).breakCombo();
    for (final c in _wiggleControllers) {
      c.forward(from: 0);
    }
  }

  void _generateConfetti() {
    _confettiParticles = List.generate(50, (_) {
      return _ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.4 + 0.2,
        dx: (_random.nextDouble() - 0.5) * 200,
        dy: -_random.nextDouble() * 300 - 100,
        rotation: _random.nextDouble() * pi * 2,
        color: [
          const Color(0xFF3B82F6),
          const Color(0xFF10B981),
          const Color(0xFFF59E0B),
          const Color(0xFF8B5CF6),
          const Color(0xFFEF4444),
          const Color(0xFFF97316),
        ][_random.nextInt(6)],
        size: _random.nextDouble() * 8 + 4,
      );
    });
  }

  void _generateXpOrbs() {
    _xpOrbs = List.generate(7, (i) {
      return _XpOrb(
        startX: 0.2 + _random.nextDouble() * 0.6,
        startY: 0.4 + _random.nextDouble() * 0.3,
        delay: i * 0.1,
      );
    });
  }

  Future<void> _awardXp(String userId, int amount) async {
    try {
      await supabase.from('xp_events').insert({
        'user_id': userId,
        'amount': amount,
        'reason': 'skill_mode_shuffle',
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(smSessionProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shuffle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final card = _card;
    if (card == null || card.sentenceTiles == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shuffle')),
        body: const Center(child: Text('Card not found')),
      );
    }

    final tiles = card.sentenceTiles!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Card ${session.cardsReviewed + 1} of ${session.totalCards}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    '${session.currentXp} XP',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instruction.
                Text(
                  'Arrange the tiles in the correct word order',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),

                // Native sentence reference.
                Text(
                  card.nativeText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),

                // Draggable tile area.
                Expanded(
                  child: _buildTileArea(tiles, theme),
                ),

                const SizedBox(height: 16),

                // Check button (manual check for non-drag users).
                if (!_solved)
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_listEquals(_currentOrder, _correctOrder)) {
                          _onSolved();
                        } else {
                          _triggerWiggle();
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Check Order'),
                    ),
                  ),

                if (_solved)
                  Center(
                    child: Text(
                      'Perfect!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF59E0B),
                      ),
                    ).animate().scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                        ),
                  ),
              ],
            ),
          ),

          // Confetti overlay.
          if (_solved)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(
                    particles: _confettiParticles,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),

          // XP orbs overlay.
          if (_solved)
            AnimatedBuilder(
              animation: _xpOrbController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _XpOrbPainter(
                    orbs: _xpOrbs,
                    progress: _xpOrbController.value,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTileArea(List<Map<String, dynamic>> tiles, ThemeData theme) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final scale = Tween<double>(begin: 1.0, end: 1.05)
                .animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ))
                .value;
            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorder: _onReorder,
      itemCount: _currentOrder.length,
      itemBuilder: (context, index) {
        final tileIndex = _currentOrder[index];
        final t = tiles[tileIndex];
        final wiggle = index < _wiggleControllers.length
            ? _wiggleControllers[index]
            : null;
        final snap = index < _snapControllers.length
            ? _snapControllers[index]
            : null;

        Widget tile = SmTileWidget(
          foreignText: t['word'] as String? ?? '',
          tileType: t['type'] as String? ?? 'standard',
          partOfSpeech: t['pos'] as String?,
          nativeOpacity: 0.0,
          tileConfig: t['tile_config'] as Map<String, dynamic>?,
        );

        // Gold glow on solved.
        if (_solved && snap != null) {
          tile = AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B)
                          .withAlpha((150 * _glowController.value *
                                  (1 - _glowController.value) * 4)
                              .round()
                              .clamp(0, 255)),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: tile,
          );
        }

        // Wiggle animation on wrong answer.
        if (!_solved && wiggle != null) {
          tile = AnimatedBuilder(
            animation: wiggle,
            builder: (context, child) {
              final offset = sin(wiggle.value * pi * 6) * 8;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: tile,
          );
        }

        return ReorderableDragStartListener(
          key: ValueKey(tileIndex),
          index: index,
          enabled: !_solved,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: tile,
          ),
        );
      },
    );
  }
}

/// Confetti particle data.
class _ConfettiParticle {
  final double x;
  final double y;
  final double dx;
  final double dy;
  final double rotation;
  final Color color;
  final double size;

  const _ConfettiParticle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.color,
    required this.size,
  });
}

/// Confetti painter.
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withAlpha((255 * (1 - progress)).round().clamp(0, 255));
      final x = p.x * size.width + p.dx * progress;
      final y = p.y * size.height + p.dy * progress + 200 * progress * progress;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// XP orb data.
class _XpOrb {
  final double startX;
  final double startY;
  final double delay;

  const _XpOrb({
    required this.startX,
    required this.startY,
    required this.delay,
  });
}

/// XP orb painter — orbs fly to top-right (HUD area).
class _XpOrbPainter extends CustomPainter {
  final List<_XpOrb> orbs;
  final double progress;

  _XpOrbPainter({required this.orbs, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final targetX = size.width - 60;
    const targetY = 20.0;

    for (final orb in orbs) {
      final t = ((progress - orb.delay) / (1 - orb.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final curve = Curves.easeInQuad.transform(t);
      final x = orb.startX * size.width + (targetX - orb.startX * size.width) * curve;
      final y = orb.startY * size.height + (targetY - orb.startY * size.height) * curve;
      final arcY = y - sin(t * pi) * 40;
      final orbSize = 6.0 * (1 - t * 0.5);
      final alpha = (255 * (1 - t * 0.3)).round().clamp(0, 255);

      final paint = Paint()
        ..color = const Color(0xFFF59E0B).withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, arcY), orbSize, paint);

      // Core bright spot.
      final corePaint = Paint()
        ..color = const Color(0xFFFFF7ED).withAlpha(alpha);
      canvas.drawCircle(Offset(x, arcY), orbSize * 0.4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _XpOrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
