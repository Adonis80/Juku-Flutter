import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_state.dart';
import '../models/sm_duo_battle.dart';
import '../services/sm_duo_battle_service.dart';

/// Duo Battle lobby — matchmaking queue with animated waiting state (SM-8).
class SmDuoLobbyScreen extends ConsumerStatefulWidget {
  const SmDuoLobbyScreen({super.key});

  @override
  ConsumerState<SmDuoLobbyScreen> createState() => _SmDuoLobbyScreenState();
}

class _SmDuoLobbyScreenState extends ConsumerState<SmDuoLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _service = SmDuoBattleService();
  SmDuoBattle? _battle;
  SmDuoStats? _stats;
  bool _searching = false;
  String _selectedLanguage = 'de';
  late AnimationController _pulseController;
  StreamSubscription<SmDuoBattle>? _subscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _subscription?.cancel();
    _service.unsubscribe();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final stats = await _service.getStats(user.id);
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _startSearching() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _searching = true);

    final battle = await _service.findOrCreateBattle(
      userId: user.id,
      language: _selectedLanguage,
    );

    if (mounted) {
      setState(() => _battle = battle);

      if (battle.status == 'matched') {
        _onMatched(battle);
      } else {
        // Subscribe for when opponent joins
        _subscription = _service.subscribeToBattle(battle.id).listen((updated) {
          if (updated.status == 'matched' && mounted) {
            _onMatched(updated);
          }
        });
      }
    }
  }

  void _onMatched(SmDuoBattle battle) {
    _subscription?.cancel();
    setState(() {
      _battle = battle;
      _searching = false;
    });
    // Navigate to battle screen after short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.push('/skill-mode/duo-battle/${battle.id}');
      }
    });
  }

  Future<void> _cancelSearch() async {
    _subscription?.cancel();
    await _service.unsubscribe();
    if (_battle != null) {
      await _service.abandonBattle(_battle!.id);
    }
    if (mounted) {
      setState(() {
        _searching = false;
        _battle = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duo Battle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_searching) {
              _cancelSearch();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Stats card
            if (_stats != null) _buildStatsCard(theme, cs),
            const SizedBox(height: 24),

            if (_battle?.status == 'matched') ...[
              // Matched!
              _buildMatchedCard(theme, cs),
            ] else if (_searching) ...[
              // Searching animation
              const Spacer(),
              _buildSearchingState(theme, cs),
              const Spacer(),
            ] else ...[
              // Language selector + start
              _buildLanguageSelector(theme),
              const Spacer(),
              _buildStartButton(theme),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, ColorScheme cs) {
    final stats = _stats!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn('Battles', '${stats.totalBattles}', theme),
            _statColumn('Wins', '${stats.wins}', theme),
            _statColumn(
              'Win Rate',
              '${(stats.winRate * 100).toStringAsFixed(0)}%',
              theme,
            ),
            _statColumn('Elo', '${stats.eloRating}', theme),
            _statColumn('Streak', '${stats.winStreak}', theme),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(ThemeData theme) {
    final languages = {
      'de': '\u{1F1E9}\u{1F1EA} German',
      'fr': '\u{1F1EB}\u{1F1F7} French',
      'ru': '\u{1F1F7}\u{1F1FA} Russian',
      'ar': '\u{1F1F8}\u{1F1E6} Arabic',
      'zh': '\u{1F1E8}\u{1F1F3} Mandarin',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: languages.entries.map((e) {
            return FilterChip(
              selected: _selectedLanguage == e.key,
              label: Text(e.value),
              onSelected: (s) {
                if (s) setState(() => _selectedLanguage = e.key);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchingState(ThemeData theme, ColorScheme cs) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, _) {
            final scale = 1.0 + (_pulseController.value * 0.15);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primaryContainer,
                  border: Border.all(
                    color: cs.primary.withValues(
                      alpha: 0.3 + (_pulseController.value * 0.4),
                    ),
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.search,
                  size: 48,
                  color: cs.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Finding an opponent...',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Waiting for another player',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _cancelSearch,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildMatchedCard(ThemeData theme, ColorScheme cs) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people,
              size: 80,
              color: cs.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Opponent Found!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Battle starting...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _startSearching,
        icon: const Icon(Icons.flash_on),
        label: const Text('Find Opponent'),
      ),
    );
  }
}
