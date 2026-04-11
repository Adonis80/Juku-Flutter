import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import 'challenge_service.dart';

/// Shows the result of a daily challenge attempt + leaderboard.
class ChallengeResultScreen extends StatefulWidget {
  const ChallengeResultScreen({
    super.key,
    this.result,
    this.correct,
    this.score,
    this.timeMs,
    required this.challengeId,
  });

  final ChallengeResult? result;
  final bool? correct;
  final int? score;
  final int? timeMs;
  final String challengeId;

  @override
  State<ChallengeResultScreen> createState() => _ChallengeResultScreenState();
}

class _ChallengeResultScreenState extends State<ChallengeResultScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final leaderboard =
        await ChallengeService.instance.getLeaderboard(widget.challengeId);
    final streak = await ChallengeService.instance.getCurrentStreak();

    if (mounted) {
      setState(() {
        _leaderboard = leaderboard;
        _currentStreak = widget.result?.streak ?? streak;
        _loading = false;
      });
    }
  }

  void _shareResult() {
    final result = widget.result;
    if (result == null) return;

    final emoji = widget.correct == true ? '\u{2705}' : '\u{274C}';
    final text = 'Juku Daily Challenge\n'
        '$emoji Score: ${widget.score ?? 0}\n'
        '\u{1F3C6} Rank: #${result.rank} (top ${result.percentile}%)\n'
        '\u{1F525} Streak: ${result.streak} days\n'
        '\u{2728} +${result.xpEarned} XP\n\n'
        '#JukuChallenge';

    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge Result')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Result card
                  if (result != null) _buildResultCard(theme, result),
                  const SizedBox(height: 24),

                  // Share button
                  if (result != null)
                    FilledButton.icon(
                      onPressed: _shareResult,
                      icon: const Icon(Icons.share),
                      label: const Text('Share Result'),
                    ),
                  const SizedBox(height: 24),

                  // Leaderboard
                  _buildLeaderboard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildResultCard(ThemeData theme, ChallengeResult result) {
    final isCorrect = widget.correct == true;

    return Card(
      color: isCorrect
          ? Colors.green.withValues(alpha: 0.1)
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isCorrect ? '\u{1F389}' : '\u{1F614}',
              style: const TextStyle(fontSize: 48),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 12),
            Text(
              isCorrect ? 'Correct!' : 'Not quite...',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatTile(
                  label: 'Score',
                  value: '${widget.score ?? 0}',
                  icon: Icons.star,
                ),
                _StatTile(
                  label: 'Rank',
                  value: '#${result.rank}',
                  icon: Icons.leaderboard,
                ),
                _StatTile(
                  label: 'Top',
                  value: '${result.percentile}%',
                  icon: Icons.trending_up,
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Streak + XP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u{1F525}',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$_currentStreak day streak',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${result.xpEarned} XP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms),

            if (widget.timeMs != null) ...[
              const SizedBox(height: 8),
              Text(
                'Time: ${(widget.timeMs! / 1000).toStringAsFixed(1)}s',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Global Leaderboard',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_leaderboard.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No attempts yet')),
            ),
          )
        else
          ..._leaderboard.indexed.map((entry) {
            final (index, attempt) = entry;
            final rank = index + 1;
            final name = (attempt['profiles']
                    as Map<String, dynamic>?)?['display_name'] as String? ??
                'Unknown';
            final score = attempt['score'] as int? ?? 0;
            final timeMs = attempt['time_ms'] as int? ?? 0;

            final medals = {1: '\u{1F947}', 2: '\u{1F948}', 3: '\u{1F949}'};
            final medalEmoji = medals[rank];

            return Card(
              child: ListTile(
                leading: SizedBox(
                  width: 32,
                  child: Center(
                    child: medalEmoji != null
                        ? Text(medalEmoji,
                            style: const TextStyle(fontSize: 20))
                        : Text(
                            '#$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                  ),
                ),
                title: Text(name),
                subtitle: Text(
                  '${(timeMs / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '$score',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
