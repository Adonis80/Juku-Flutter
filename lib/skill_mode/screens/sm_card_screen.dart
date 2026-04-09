import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../models/sm_card.dart';
import '../services/sm_audio_service.dart';
import '../state/sm_session_notifier.dart';
import '../widgets/animations/sm_magnet_transform.dart';
import '../widgets/tile/sm_tile_row.dart';
import '../widgets/tile/sm_tile_widget.dart';
import 'sm_grammar_panel.dart';

/// Three-press card states.
enum SmCardState { covered, revealed, transformed, grammar }

/// Single card view with three-press interaction (SM-1.6).
///
/// States: covered → revealed → transformed → (grammar overlay)
/// - Press 1: Reveal — tiles cascade face-up in native order
/// - Press 2: Magnet Transform — tiles spring to foreign order
/// - Press 3: Grammar Panel — bottom sheet with annotations
class SmCardScreen extends ConsumerStatefulWidget {
  final String cardId;
  const SmCardScreen({super.key, required this.cardId});

  @override
  ConsumerState<SmCardScreen> createState() => _SmCardScreenState();
}

class _SmCardScreenState extends ConsumerState<SmCardScreen>
    with TickerProviderStateMixin {
  SmCard? _card;
  bool _loading = true;
  SmCardState _state = SmCardState.covered;
  bool _showForeignOrder = false;
  double _nativeOpacity = 1.0;

  // Reveal cascade
  late List<AnimationController> _flipControllers;
  bool _revealStarted = false;

  // Audio
  final _audio = SmAudioService.instance;

  @override
  void initState() {
    super.initState();
    _flipControllers = [];
    _loadCard();
  }

  @override
  void dispose() {
    for (final c in _flipControllers) {
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

      if (mounted) {
        final card = SmCard.fromJson(data);
        final tileCount = card.sentenceTiles?.length ?? 1;
        _flipControllers = List.generate(
          tileCount,
          (_) => AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          ),
        );

        setState(() {
          _card = card;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onPress() {
    switch (_state) {
      case SmCardState.covered:
        _reveal();
      case SmCardState.revealed:
        _transform();
      case SmCardState.transformed:
        _showGrammar();
      case SmCardState.grammar:
        break;
    }
  }

  /// Press 1: Reveal — cascade tiles face-up with 40ms stagger.
  void _reveal() {
    if (_revealStarted) return;
    _revealStarted = true;
    setState(() => _state = SmCardState.revealed);

    for (var i = 0; i < _flipControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 40 * i), () {
        if (mounted) {
          _flipControllers[i].forward();
        }
      });
    }

    // Play audio after tile cascade completes.
    final card = _card;
    if (card != null) {
      final cascadeMs = 40 * _flipControllers.length + 300;
      Future.delayed(Duration(milliseconds: cascadeMs), () {
        if (mounted) _audio.playCardAudio(card);
      });
    }

    // Award XP on first reveal
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(smSessionProvider.notifier).addXp(5);
      _awardXp(user.id, 5);
    }
  }

  /// Press 2: Magnet Transform — tiles spring to foreign order.
  void _transform() {
    setState(() {
      _state = SmCardState.transformed;
      _showForeignOrder = true;
      _nativeOpacity = 0.3;
    });

    // Play audio after magnet animation settles (~800ms).
    final card = _card;
    if (card != null) {
      Future.delayed(const Duration(milliseconds: 850), () {
        if (mounted) _audio.playCardAudio(card);
      });
    }
  }

  /// Press 3: Grammar Panel.
  void _showGrammar() {
    final card = _card;
    if (card == null) return;
    setState(() => _state = SmCardState.grammar);
    SmGrammarPanel.show(
      context,
      tiles: card.sentenceTiles ?? [],
      grammarMetadata: card.grammarMetadata,
    ).then((_) {
      if (mounted) {
        setState(() => _state = SmCardState.transformed);
      }
    });
  }

  void _toggleOrder() {
    setState(() {
      _showForeignOrder = !_showForeignOrder;
      _nativeOpacity = _showForeignOrder ? 0.3 : 1.0;
    });
  }

  Future<void> _awardXp(String userId, int amount) async {
    try {
      await supabase.from('xp_events').insert({
        'user_id': userId,
        'amount': amount,
        'reason': 'skill_mode_reveal',
      });
    } catch (_) {
      // Non-blocking
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(smSessionProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Card')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final card = _card;
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Card')),
        body: const Center(child: Text('Card not found')),
      );
    }

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
          // XP display
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
      body: GestureDetector(
        onTap: _onPress,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card type + difficulty
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.cardType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(
                    card.difficulty,
                    (_) => Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Native text
              Text(
                card.nativeText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Tile area
              if (card.cardType == 'sentence' && card.sentenceTiles != null)
                _buildSentenceCard(card)
              else
                _buildWordCard(card),

              const Spacer(),

              // Action hint
              _buildHint(theme),
              const SizedBox(height: 16),

              // Action buttons
              _buildButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentenceCard(SmCard card) {
    final tiles = card.sentenceTiles!;

    if (_state == SmCardState.covered) {
      return SmTileRow(tiles: tiles, allFaceDown: true);
    }

    if (_state == SmCardState.revealed && !_showForeignOrder) {
      // Show tiles in native order with cascade reveal
      final nativeOrder = card.nativeWordOrder ?? List.generate(tiles.length, (i) => i);
      final orderedTiles = nativeOrder.map((idx) => tiles[idx]).toList();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(orderedTiles.length, (i) {
          final t = orderedTiles[i];
          final controller =
              i < _flipControllers.length ? _flipControllers[i] : null;

          Widget tile = SmTileWidget(
            foreignText: t['word'] as String? ?? '',
            nativeText: t['native'] as String?,
            tileType: t['type'] as String? ?? 'standard',
            partOfSpeech: t['pos'] as String?,
            nativeOpacity: _nativeOpacity,
          );

          if (controller != null) {
            tile = AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                // Y-axis flip animation
                final angle = (1 - controller.value) * 3.14159;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: controller.value > 0.5
                      ? child
                      : SmTileWidget(
                          foreignText: '',
                          isFaceDown: true,
                        ),
                );
              },
              child: tile,
            );
          }

          return tile;
        }),
      );
    }

    // Transformed state — use magnet animation
    return SmMagnetTransform(
      tiles: tiles,
      nativeWordOrder:
          card.nativeWordOrder ?? List.generate(tiles.length, (i) => i),
      foreignWordOrder:
          card.foreignWordOrder ?? List.generate(tiles.length, (i) => i),
      showForeignOrder: _showForeignOrder,
      nativeOpacity: _nativeOpacity,
    );
  }

  Widget _buildWordCard(SmCard card) {
    if (_state == SmCardState.covered) {
      return const SmTileWidget(foreignText: '', isFaceDown: true);
    }

    return SmTileWidget(
      foreignText: card.foreignText,
      nativeText: card.nativeText,
      tileType: card.tileType,
      partOfSpeech: card.partOfSpeech,
      nativeOpacity: _nativeOpacity,
      tileConfig: card.tileConfig.isNotEmpty ? card.tileConfig : null,
    );
  }

  Widget _buildHint(ThemeData theme) {
    final hint = switch (_state) {
      SmCardState.covered => 'Tap to reveal',
      SmCardState.revealed => 'Tap to transform',
      SmCardState.transformed => 'Tap for grammar',
      SmCardState.grammar => '',
    };

    if (hint.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Text(
        hint,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
    );
  }

  Widget _buildButtons(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_state == SmCardState.transformed ||
            _state == SmCardState.grammar) ...[
          // Toggle order button
          IconButton.filled(
            onPressed: _toggleOrder,
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Toggle word order',
          ),
          const SizedBox(width: 16),
          // Next card
          FilledButton.icon(
            onPressed: () {
              ref.read(smSessionProvider.notifier).advanceCard();
              context.pop();
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ],
      ],
    );
  }
}
