import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../models/sm_card.dart';
import '../models/sm_duo_battle.dart';
import '../services/sm_duo_battle_service.dart';
import '../widgets/tile/sm_tile_widget.dart';

/// Duo Battle screen — split-view race showing your progress vs opponent (SM-8).
class SmDuoBattleScreen extends ConsumerStatefulWidget {
  final String battleId;
  const SmDuoBattleScreen({super.key, required this.battleId});

  @override
  ConsumerState<SmDuoBattleScreen> createState() => _SmDuoBattleScreenState();
}

class _SmDuoBattleScreenState extends ConsumerState<SmDuoBattleScreen> {
  final _service = SmDuoBattleService();
  SmDuoBattle? _battle;
  List<SmCard> _cards = [];
  int _currentCardIndex = 0;
  bool _loading = true;
  String? _userId;
  StreamSubscription<SmDuoBattle>? _subscription;

  // Timing
  final Stopwatch _cardStopwatch = Stopwatch();

  // Card interaction state
  bool _revealed = false;
  bool _answered = false;
  List<int> _shuffledOrder = [];
  List<int> _userOrder = [];

  @override
  void initState() {
    super.initState();
    _userId = supabase.auth.currentUser?.id;
    _loadBattle();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.unsubscribe();
    super.dispose();
  }

  Future<void> _loadBattle() async {
    try {
      final data = await supabase
          .from('skill_mode_duo_battles')
          .select()
          .eq('id', widget.battleId)
          .single();

      final battle = SmDuoBattle.fromJson(data);

      // Load all cards
      final cards = <SmCard>[];
      for (final cardId in battle.cardIds) {
        final cardData = await supabase
            .from('skill_mode_cards')
            .select()
            .eq('id', cardId)
            .maybeSingle();
        if (cardData != null) {
          cards.add(SmCard.fromJson(cardData));
        }
      }

      if (mounted) {
        setState(() {
          _battle = battle;
          _cards = cards;
          _loading = false;
        });

        // Start the battle if matched
        if (battle.status == 'matched') {
          await _service.startBattle(battle.id);
        }

        // Subscribe to realtime updates
        _subscription = _service.subscribeToBattle(battle.id).listen((updated) {
          if (mounted) {
            setState(() => _battle = updated);
            if (updated.isFinished) {
              _onBattleFinished(updated);
            }
          }
        });

        _startCard();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCard() {
    if (_currentCardIndex >= _cards.length) {
      _finishBattle();
      return;
    }

    final card = _cards[_currentCardIndex];
    final tileCount = card.sentenceTiles?.length ?? 1;

    // Create shuffled order for puzzle
    _shuffledOrder = List.generate(tileCount, (i) => i)..shuffle();
    _userOrder = List.from(_shuffledOrder);
    _revealed = false;
    _answered = false;
    _cardStopwatch
      ..reset()
      ..start();
  }

  void _revealCard() {
    setState(() => _revealed = true);
  }

  void _onTileReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _userOrder.removeAt(oldIndex);
      _userOrder.insert(newIndex, item);
    });

    // Check if correct
    final card = _cards[_currentCardIndex];
    final correctOrder =
        card.foreignWordOrder ?? List.generate(_userOrder.length, (i) => i);

    bool isCorrect = true;
    for (var i = 0; i < _userOrder.length; i++) {
      if (_userOrder[i] != correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _onCardCorrect();
    }
  }

  Future<void> _onCardCorrect() async {
    _cardStopwatch.stop();
    setState(() => _answered = true);

    if (_userId == null || _battle == null) return;

    await _service.submitRound(
      battleId: _battle!.id,
      playerId: _userId!,
      cardId: _cards[_currentCardIndex].id,
      roundIndex: _currentCardIndex,
      correct: true,
      timeMs: _cardStopwatch.elapsedMilliseconds,
    );

    // Short celebration then next card
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _currentCardIndex++;
      });
      _startCard();
    }
  }

  void _skipCard() async {
    _cardStopwatch.stop();

    if (_userId == null || _battle == null) return;

    await _service.submitRound(
      battleId: _battle!.id,
      playerId: _userId!,
      cardId: _cards[_currentCardIndex].id,
      roundIndex: _currentCardIndex,
      correct: false,
      timeMs: _cardStopwatch.elapsedMilliseconds,
    );

    if (mounted) {
      setState(() {
        _currentCardIndex++;
      });
      _startCard();
    }
  }

  Future<void> _finishBattle() async {
    if (_battle == null) return;
    final result = await _service.finishBattle(_battle!.id);
    if (mounted) _onBattleFinished(result);
  }

  void _onBattleFinished(SmDuoBattle battle) {
    context.pushReplacement('/skill-mode/duo-results/${battle.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Duo Battle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty || _battle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Duo Battle')),
        body: const Center(child: Text('Battle not found')),
      );
    }

    final battle = _battle!;
    final userId = _userId ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Score bar — your score vs opponent
            _buildScoreBar(theme, cs, battle, userId),
            // Progress indicators
            _buildProgressBar(theme, cs, battle, userId),
            const SizedBox(height: 16),

            // Card area
            Expanded(
              child: _currentCardIndex < _cards.length
                  ? _buildCardArea(theme, cs)
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for opponent to finish...',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(
    ThemeData theme,
    ColorScheme cs,
    SmDuoBattle battle,
    String userId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest),
      child: Row(
        children: [
          // My score
          Column(
            children: [
              Text(
                'You',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.primary),
              ),
              Text(
                '${battle.myScore(userId)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VS',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onErrorContainer,
              ),
            ),
          ),
          const Spacer(),
          // Opponent score
          Column(
            children: [
              Text(
                'Opponent',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.error),
              ),
              Text(
                '${battle.opponentScore(userId)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    ThemeData theme,
    ColorScheme cs,
    SmDuoBattle battle,
    String userId,
  ) {
    final total = battle.cardCount;
    final myDone = battle.myCardsDone(userId);
    final opDone = battle.opponentCardsDone(userId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // My progress
          Row(
            children: [
              Text('You: $myDone/$total', style: theme.textTheme.labelSmall),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: total > 0 ? myDone / total : 0,
                  color: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Opponent progress
          Row(
            children: [
              Text('Opp: $opDone/$total', style: theme.textTheme.labelSmall),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: total > 0 ? opDone / total : 0,
                  color: cs.error,
                  backgroundColor: cs.error.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardArea(ThemeData theme, ColorScheme cs) {
    final card = _cards[_currentCardIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card counter
          Text(
            'Card ${_currentCardIndex + 1} of ${_cards.length}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Native text (clue)
          Text(
            card.nativeText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          if (!_revealed) ...[
            // Tap to reveal
            Center(
              child: FilledButton.icon(
                onPressed: _revealCard,
                icon: const Icon(Icons.visibility),
                label: const Text('Reveal'),
              ),
            ),
          ] else if (card.sentenceTiles != null &&
              card.sentenceTiles!.length > 1) ...[
            // Reorderable tiles for sentences
            Text(
              'Drag tiles into correct order:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: _onTileReorder,
              children: [
                for (var i = 0; i < _userOrder.length; i++)
                  Padding(
                    key: ValueKey(_userOrder[i]),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SmTileWidget(
                      foreignText:
                          card.sentenceTiles![_userOrder[i]]['word']
                              as String? ??
                          '',
                      tileType:
                          card.sentenceTiles![_userOrder[i]]['type']
                              as String? ??
                          'standard',
                      partOfSpeech:
                          card.sentenceTiles![_userOrder[i]]['pos'] as String?,
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Word card — just show it and mark done
            SmTileWidget(
              foreignText: card.foreignText,
              tileType: card.tileType,
              partOfSpeech: card.partOfSpeech,
            ),
            const SizedBox(height: 16),
            if (!_answered)
              FilledButton(
                onPressed: _onCardCorrect,
                child: const Text('Got it!'),
              ),
          ],

          if (_answered)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Icon(Icons.check_circle, size: 48, color: cs.primary),
              ),
            ),

          const Spacer(),

          // Skip button
          if (!_answered && _revealed)
            Center(
              child: TextButton(
                onPressed: _skipCard,
                child: const Text('Skip'),
              ),
            ),
        ],
      ),
    );
  }
}
