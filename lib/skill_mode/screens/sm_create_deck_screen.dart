import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../services/sm_xp_engine.dart';

/// Deck Forge — multi-step deck creation flow (SM-2.5.1).
///
/// Steps: Topic → Card Entry → Forge Animation → Review → Identity → Publish
class SmCreateDeckScreen extends ConsumerStatefulWidget {
  const SmCreateDeckScreen({super.key});

  @override
  ConsumerState<SmCreateDeckScreen> createState() =>
      _SmCreateDeckScreenState();
}

class _SmCreateDeckScreenState extends ConsumerState<SmCreateDeckScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _publishing = false;

  // Step 1: Topic.
  final _topicController = TextEditingController();
  final String _language = 'de';
  String _difficulty = 'beginner';
  int _cardCount = 10;

  // Step 2: Cards (manual entry).
  final List<Map<String, dynamic>> _cards = [];
  final _foreignController = TextEditingController();
  final _nativeController = TextEditingController();
  String _tileType = 'standard';
  String _pos = 'noun';

  // Step 3: Forge animation.
  int _cardsForged = 0;
  late AnimationController _forgeController;

  // Step 4: Deck identity.
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _cardSkin = 'default';
  int _creatorTargetScore = 0;

  static const _skins = {
    'dark_academia': '🎓 Dark Academia',
    'neon_city': '🌆 Neon City',
    'nature': '🌿 Nature',
    'minimal': '◽ Minimal',
    'default': '🎨 Default',
  };

  @override
  void initState() {
    super.initState();
    _forgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _foreignController.dispose();
    _nativeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _forgeController.dispose();
    super.dispose();
  }

  void _addCard() {
    if (_foreignController.text.isEmpty || _nativeController.text.isEmpty) {
      return;
    }
    setState(() {
      _cards.add({
        'foreign_text': _foreignController.text,
        'native_text': _nativeController.text,
        'tile_type': _tileType,
        'part_of_speech': _pos,
        'language': _language,
        'difficulty': _difficulty == 'beginner'
            ? 1
            : _difficulty == 'intermediate'
                ? 2
                : 3,
      });
      _foreignController.clear();
      _nativeController.clear();
    });
  }

  void _removeCard(int index) {
    setState(() => _cards.removeAt(index));
  }

  Future<void> _runForgeAnimation() async {
    for (var i = 0; i < _cards.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _forgeController.forward(from: 0);
      setState(() => _cardsForged = i + 1);
    }
    // Move to identity step.
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _step = 3);
  }

  Future<void> _publish() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _cards.isEmpty) return;

    setState(() => _publishing = true);

    try {
      // Create deck.
      final deckData = await supabase.from('skill_mode_decks').insert({
        'creator_id': user.id,
        'title': _titleController.text.isNotEmpty
            ? _titleController.text
            : _topicController.text,
        'description': _descriptionController.text,
        'language': _language,
        'difficulty': _difficulty,
        'card_skin': _cardSkin,
        'creator_target_score':
            _creatorTargetScore > 0 ? _creatorTargetScore : null,
        'published': true,
      }).select('id').single();

      final deckId = deckData['id'] as String;

      // Insert cards.
      final cardInserts = _cards.map((c) {
        return {
          ...c,
          'deck_id': deckId,
          'card_type': 'word',
          'sentence_tiles': null,
          'native_word_order': null,
          'foreign_word_order': null,
          'grammar_metadata': <String, dynamic>{},
          'tile_config': <String, dynamic>{},
          'tags': <String>[],
        };
      }).toList();

      await supabase.from('skill_mode_cards').insert(cardInserts);

      // Award XP.
      await SmXpEngine.instance.awardXp(
        userId: user.id,
        baseAmount: 20,
        reason: 'deck_published',
        currentCombo: 0,
      );

      if (mounted) {
        setState(() => _step = 4); // Publish celebration.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e')),
        );
        setState(() => _publishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: switch (_step) {
        0 => _buildTopicStep(theme),
        1 => _buildCardEntryStep(theme),
        2 => _buildForgeStep(theme),
        3 => _buildIdentityStep(theme),
        4 => _buildPublishCelebration(theme),
        _ => const SizedBox.shrink(),
      },
    );
  }

  String get _stepTitle => switch (_step) {
        0 => 'What are you teaching?',
        1 => 'Add Cards',
        2 => 'Forging...',
        3 => 'Deck Identity',
        4 => 'Published!',
        _ => '',
      };

  // Step 0: Topic + Language.
  Widget _buildTopicStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              hintText: 'e.g. German food vocabulary — A2',
              labelText: 'Topic',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          Text('Difficulty', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'beginner', label: Text('Beginner')),
              ButtonSegment(
                  value: 'intermediate', label: Text('Intermediate')),
              ButtonSegment(value: 'advanced', label: Text('Advanced')),
            ],
            selected: {_difficulty},
            onSelectionChanged: (v) => setState(() => _difficulty = v.first),
          ),
          const SizedBox(height: 24),
          Text('How many cards?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 20, label: Text('20')),
              ButtonSegment(value: 30, label: Text('30')),
            ],
            selected: {_cardCount},
            onSelectionChanged: (v) => setState(() => _cardCount = v.first),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _topicController.text.isNotEmpty
                  ? () => setState(() => _step = 1)
                  : null,
              child: const Text('Next: Add Cards'),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Manual card entry.
  Widget _buildCardEntryStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card count.
          Text(
            '${_cards.length} of $_cardCount cards added',
            style: theme.textTheme.labelLarge,
          ),
          LinearProgressIndicator(
            value: _cards.length / _cardCount,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),

          // Entry fields.
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _foreignController,
                  decoration: const InputDecoration(
                    hintText: 'Foreign word',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nativeController,
                  decoration: const InputDecoration(
                    hintText: 'Translation',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addCard,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Type selectors.
          Row(
            children: [
              DropdownButton<String>(
                value: _tileType,
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Standard')),
                  DropdownMenuItem(
                      value: 'inflected', child: Text('Inflected')),
                  DropdownMenuItem(value: 'ghost', child: Text('Ghost')),
                  DropdownMenuItem(
                      value: 'compound', child: Text('Compound')),
                ],
                onChanged: (v) => setState(() => _tileType = v ?? 'standard'),
                underline: const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _pos,
                items: const [
                  DropdownMenuItem(value: 'noun', child: Text('Noun')),
                  DropdownMenuItem(value: 'verb', child: Text('Verb')),
                  DropdownMenuItem(
                      value: 'adjective', child: Text('Adjective')),
                  DropdownMenuItem(value: 'article', child: Text('Article')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _pos = v ?? 'noun'),
                underline: const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card list.
          Expanded(
            child: ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (_, i) {
                final c = _cards[i];
                return ListTile(
                  dense: true,
                  title: Text(c['foreign_text'] as String),
                  subtitle: Text(c['native_text'] as String),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeCard(i),
                  ),
                );
              },
            ),
          ),

          // Next button.
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _cards.isNotEmpty
                  ? () {
                      setState(() => _step = 2);
                      _runForgeAnimation();
                    }
                  : null,
              child: const Text('Forge Cards'),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Forge animation.
  Widget _buildForgeStep(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hammer icon with animation.
          AnimatedBuilder(
            animation: _forgeController,
            builder: (context, child) {
              final angle =
                  sin(_forgeController.value * pi * 2) * 0.3;
              return Transform.rotate(
                angle: angle,
                child: child,
              );
            },
            child: const Icon(
              Icons.hardware,
              size: 64,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$_cardsForged of ${_cards.length} cards forged',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: LinearProgressIndicator(
              value: _cards.isNotEmpty ? _cardsForged / _cards.length : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Deck identity.
  Widget _buildIdentityStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: _topicController.text,
              labelText: 'Deck Title',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Optional description...',
              labelText: 'Description',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Card skin picker.
          Text('Card Skin', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skins.entries.map((e) {
              final selected = _cardSkin == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _cardSkin = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Creator target score.
          Text('Beat the Creator target', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _creatorTargetScore.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: _creatorTargetScore > 0
                      ? '$_creatorTargetScore%'
                      : 'Off',
                  onChanged: (v) =>
                      setState(() => _creatorTargetScore = v.round()),
                ),
              ),
              Text(
                _creatorTargetScore > 0 ? '$_creatorTargetScore%' : 'Off',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Publish button.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _publishing ? null : _publish,
              icon: _publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish),
              label: const Text('Publish Deck'),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Publish celebration.
  Widget _buildPublishCelebration(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Color(0xFF10B981),
          )
              .animate()
              .scale(
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
              )
              .fadeIn(),
          const SizedBox(height: 16),
          Text(
            'Deck Published!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10B981),
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
          const SizedBox(height: 8),
          Text(
            '+20 XP',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFF59E0B),
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/skill-mode'),
            child: const Text('Back to Skill Mode'),
          ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
        ],
      ),
    );
  }
}
