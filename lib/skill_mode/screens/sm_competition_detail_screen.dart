import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/sm_competition.dart';
import '../state/sm_competition_notifier.dart';

/// Competition detail — song info, rules, leaderboard, enter button.
class SmCompetitionDetailScreen extends ConsumerWidget {
  final String competitionId;
  const SmCompetitionDetailScreen({super.key, required this.competitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(smCompetitionDetailProvider(competitionId));
    final theme = Theme.of(context);

    if (detail.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Competition')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (detail.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Competition')),
        body: Center(child: Text('Error: ${detail.error}')),
      );
    }

    final comp = detail.competition!;
    final entries = detail.entries;
    final myEntry = detail.myEntry;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header.
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                comp.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.tertiaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.translate,
                    size: 64,
                    color: theme.colorScheme.onPrimaryContainer.withAlpha(60),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Song info card.
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.music_note,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(comp.songTitle ?? 'Unknown Song'),
                    subtitle: Text(comp.songArtist ?? ''),
                    trailing: Text(
                      '${comp.songLanguage?.toUpperCase() ?? ""} \u{2192} ${comp.targetLanguage.toUpperCase()}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description.
                if (comp.description != null) ...[
                  Text(comp.description!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],

                // Prize info.
                _PrizeCard(competition: comp),
                const SizedBox(height: 16),

                // Phase info.
                _PhaseTimeline(competition: comp),
                const SizedBox(height: 24),

                // Action button.
                if (comp.isActive && myEntry == null && !comp.isFull)
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/skill-mode/competition/${comp.id}/enter',
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Enter Competition'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  )
                else if (comp.isActive && myEntry != null)
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/skill-mode/competition/${comp.id}/enter',
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit My Entry'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  )
                else if (comp.isActive && comp.isFull)
                  const _InfoBanner(
                    text: 'Competition is full',
                    icon: Icons.block,
                  )
                else if (comp.isVoting)
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/skill-mode/competition/${comp.id}/vote'),
                    icon: const Icon(Icons.how_to_vote),
                    label: const Text('Vote on Entries'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),

                const SizedBox(height: 24),

                // Leaderboard.
                if (entries.isNotEmpty) ...[
                  Text(
                    comp.isCompleted
                        ? 'Final Results'
                        : 'Entries (${entries.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...entries.asMap().entries.map(
                    (e) => _EntryRow(
                      entry: e.value,
                      position: e.key + 1,
                      isCompleted: comp.isCompleted,
                      myVoteScore: detail.myVotes[e.value.id],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final SmCompetition competition;
  const _PrizeCard({required this.competition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = competition;

    return Card(
      color: theme.colorScheme.tertiaryContainer.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prizes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PrizePill(
                  label: '1st',
                  xp: c.xpFirst,
                  juice: c.prizePoolJuice ~/ 2,
                ),
                _PrizePill(
                  label: '2nd',
                  xp: c.xpSecond,
                  juice: c.prizePoolJuice ~/ 3,
                ),
                _PrizePill(
                  label: '3rd',
                  xp: c.xpThird,
                  juice: c.prizePoolJuice ~/ 6,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'All participants: +${c.xpParticipation} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrizePill extends StatelessWidget {
  final String label;
  final int xp;
  final int juice;
  const _PrizePill({
    required this.label,
    required this.xp,
    required this.juice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text('+$xp XP', style: theme.textTheme.labelSmall),
        Text(
          '+$juice Juice',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _PhaseTimeline extends StatelessWidget {
  final SmCompetition competition;
  const _PhaseTimeline({required this.competition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = competition;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _TimelineRow(
              label: 'Submissions Open',
              time: c.startsAt,
              isActive: c.isActive,
              isPast: !c.isUpcoming,
            ),
            _TimelineRow(
              label: 'Submissions Close',
              time: c.submissionDeadline,
              isActive: false,
              isPast: c.isVoting || c.isCompleted,
            ),
            _TimelineRow(
              label: 'Voting Ends',
              time: c.votingDeadline,
              isActive: c.isVoting,
              isPast: c.isCompleted,
            ),
            _TimelineRow(
              label: 'Results',
              time: c.endsAt,
              isActive: false,
              isPast: c.isCompleted,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool isActive;
  final bool isPast;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.time,
    this.isActive = false,
    this.isPast = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : isPast
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isPast
                ? Icons.check_circle
                : isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : null,
              ),
            ),
          ),
          Text(
            _formatDate(time),
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _EntryRow extends StatelessWidget {
  final SmCompetitionEntry entry;
  final int position;
  final bool isCompleted;
  final int? myVoteScore;

  const _EntryRow({
    required this.entry,
    required this.position,
    required this.isCompleted,
    this.myVoteScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopThree = position <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTopThree && isCompleted
              ? [
                  const Color(0xFFFFD700),
                  const Color(0xFFC0C0C0),
                  const Color(0xFFCD7F32),
                ][position - 1]
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            '$position',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isTopThree && isCompleted
                  ? Colors.white
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        title: Text(
          entry.translatorUsername ?? 'Anonymous',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: entry.styleNote != null
            ? Text(
                entry.styleNote!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: theme.colorScheme.tertiary),
                const SizedBox(width: 2),
                Text(
                  entry.qualityScore.toStringAsFixed(1),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              '${entry.totalVotes} votes',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InfoBanner({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
