import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../models/sm_challenge.dart';
import '../services/sm_challenge_service.dart';

/// Challenge Mode hub — pending challenges, send new, history (SM-9).
class SmChallengeScreen extends ConsumerStatefulWidget {
  const SmChallengeScreen({super.key});

  @override
  ConsumerState<SmChallengeScreen> createState() => _SmChallengeScreenState();
}

class _SmChallengeScreenState extends ConsumerState<SmChallengeScreen>
    with SingleTickerProviderStateMixin {
  final _service = SmChallengeService();
  late TabController _tabController;
  List<SmChallenge> _pending = [];
  List<SmChallenge> _sent = [];
  List<SmChallenge> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final pending = await _service.getPendingChallenges(user.id);
      final sent = await _service.getSentChallenges(user.id);
      final history = await _service.getChallengeHistory(userId: user.id);

      if (mounted) {
        setState(() {
          _pending = pending;
          _sent = sent;
          _history = history;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inbox'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: cs.error,
                      child: Text(
                        '${_pending.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Sent'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChallengeList(_pending, 'received', theme, cs),
                _buildChallengeList(_sent, 'sent', theme, cs),
                _buildChallengeList(_history, 'history', theme, cs),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSendDialog(context, theme),
        icon: const Icon(Icons.send),
        label: const Text('Send Challenge'),
      ),
    );
  }

  Widget _buildChallengeList(
    List<SmChallenge> challenges,
    String type,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_kabaddi,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'received'
                  ? 'No pending challenges'
                  : type == 'sent'
                  ? 'No sent challenges'
                  : 'No challenge history',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (_, i) =>
          _buildChallengeCard(challenges[i], type, theme, cs),
    );
  }

  Widget _buildChallengeCard(
    SmChallenge challenge,
    String type,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final isChallenger = challenge.challengerId == userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.sports_kabaddi, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isChallenger
                        ? 'You challenged ${challenge.challengedUsername ?? "someone"}'
                        : '${challenge.challengerUsername ?? "Someone"} challenged you!',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _statusChip(challenge, theme, cs),
              ],
            ),
            // Taunt
            if (challenge.tauntMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('\u{1F4AC} ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        '"${challenge.tauntMessage}"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Score comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _scoreBlock(
                  'Challenger',
                  challenge.challengerScore,
                  challenge.didChallengerWin(),
                  theme,
                  cs,
                ),
                Text('vs', style: theme.textTheme.labelMedium),
                _scoreBlock(
                  'Challenged',
                  challenge.challengedScore,
                  challenge.didChallengedWin(),
                  theme,
                  cs,
                ),
              ],
            ),
            // Actions for pending received challenges
            if (type == 'received' && challenge.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _service.declineChallenge(challenge.id);
                        _loadAll();
                      },
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await _service.acceptChallenge(challenge.id);
                        if (mounted) {
                          // Navigate to play the card/deck
                          if (challenge.cardId != null) {
                            context.push(
                              '/skill-mode/card/${challenge.cardId}',
                            );
                          } else if (challenge.deckId != null) {
                            context.push(
                              '/skill-mode/deck-detail/${challenge.deckId}',
                            );
                          }
                        }
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(SmChallenge challenge, ThemeData theme, ColorScheme cs) {
    final (label, color) = switch (challenge.status) {
      'pending' => ('Pending', cs.tertiary),
      'accepted' => ('In Progress', cs.primary),
      'completed' => ('Completed', Colors.green),
      'declined' => ('Declined', cs.error),
      'expired' => ('Expired', cs.outline),
      _ => (challenge.status, cs.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _scoreBlock(
    String label,
    int? score,
    bool isWinner,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score != null ? '$score' : '?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isWinner ? Colors.amber.shade700 : cs.onSurface,
              ),
            ),
            if (isWinner) ...[
              const SizedBox(width: 4),
              const Text('\u{1F3C6}', style: TextStyle(fontSize: 18)),
            ],
          ],
        ),
      ],
    );
  }

  void _showSendDialog(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SendChallengeSheet(
        onSend: (friendId, taunt) async {
          Navigator.pop(ctx);
          // For now, navigate to a card to set the score
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Play a card first, then challenge from the results screen!',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SendChallengeSheet extends StatefulWidget {
  final Future<void> Function(String friendId, String? taunt) onSend;

  const _SendChallengeSheet({required this.onSend});

  @override
  State<_SendChallengeSheet> createState() => _SendChallengeSheetState();
}

class _SendChallengeSheetState extends State<_SendChallengeSheet> {
  final _service = SmChallengeService();
  final _tauntController = TextEditingController();
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _tauntController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final friends = await _service.getChallengeFriends(userId);
      if (mounted) {
        setState(() {
          _friends = friends;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send Challenge', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Pick a friend to challenge:', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_friends.isEmpty)
            const Text('Follow some users to challenge them!')
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (_, i) {
                  final friend = _friends[i];
                  final profile =
                      friend['profiles'] as Map<String, dynamic>? ?? {};
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile['photo_url'] != null
                          ? NetworkImage(profile['photo_url'] as String)
                          : null,
                      child: profile['photo_url'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(profile['username'] as String? ?? 'User'),
                    onTap: () => widget.onSend(
                      friend['following_id'] as String,
                      _tauntController.text.trim().isEmpty
                          ? null
                          : _tauntController.text.trim(),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _tauntController,
            decoration: const InputDecoration(
              labelText: 'Taunt message (optional)',
              hintText: 'Think you can beat this? \u{1F60F}',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
