import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_state.dart';
import '../models/sm_card.dart';
import '../state/sm_deck_notifier.dart';
import '../state/sm_session_notifier.dart';
import '../services/sm_supabase_service.dart';

/// Card queue screen for a Skill Mode session (SM-1.6).
///
/// Loads due cards from `skill_mode_user_cards` (max 20),
/// creates a session record, and navigates through cards.
class SmDeckScreen extends ConsumerStatefulWidget {
  const SmDeckScreen({super.key});

  @override
  ConsumerState<SmDeckScreen> createState() => _SmDeckScreenState();
}

class _SmDeckScreenState extends ConsumerState<SmDeckScreen> {
  final _service = SmSupabaseService();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _error = 'Not signed in';
        _loading = false;
      });
      return;
    }

    try {
      // Load deck
      await ref.read(smDeckProvider.notifier).loadDeck(
            userId: user.id,
            language: 'de',
          );

      final cards = ref.read(smDeckProvider).value ?? [];

      if (cards.isEmpty) {
        setState(() {
          _error = 'No cards available';
          _loading = false;
        });
        return;
      }

      // Create session
      final sessionId = await _service.createSession(
        userId: user.id,
        language: 'de',
      );

      ref.read(smSessionProvider.notifier).startSession(
            sessionId: sessionId,
            totalCards: cards.length,
          );

      setState(() => _loading = false);

      // Navigate to first card
      if (mounted) {
        _navigateToCard(cards.first);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load session: $e';
          _loading = false;
        });
      }
    }
  }

  void _navigateToCard(SmCard card) {
    context.push('/skill-mode/card/${card.id}').then((_) {
      if (!mounted) return;
      _checkNextCard();
    });
  }

  void _checkNextCard() {
    final session = ref.read(smSessionProvider);
    final cards = ref.read(smDeckProvider).value ?? [];

    if (session.cardsReviewed >= cards.length) {
      _endSession();
      return;
    }

    if (session.cardsReviewed < cards.length) {
      _navigateToCard(cards[session.cardsReviewed]);
    }
  }

  Future<void> _endSession() async {
    final session = ref.read(smSessionProvider);
    final user = ref.read(currentUserProvider);

    if (session.sessionId != null && user != null) {
      try {
        await _service.endSession(
          sessionId: session.sessionId!,
          cardsReviewed: session.cardsReviewed,
          xpEarned: session.currentXp,
          comboPeak: session.comboPeak,
        );
      } catch (_) {
        // Non-blocking
      }
    }

    if (mounted) {
      _showSessionSummary();
    }
  }

  void _showSessionSummary() {
    final session = ref.read(smSessionProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(Icons.style, '${session.cardsReviewed} cards reviewed'),
            const SizedBox(height: 8),
            _summaryRow(Icons.star, '${session.currentXp} XP earned'),
            const SizedBox(height: 8),
            _summaryRow(
                Icons.local_fire_department, '${session.comboPeak}x best combo'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/skill-mode');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/skill-mode'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/skill-mode'),
                child: const Text('Back to Skill Mode'),
              ),
            ],
          ),
        ),
      );
    }

    // This screen primarily navigates to card screens.
    // When all cards done, it shows the summary dialog.
    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
