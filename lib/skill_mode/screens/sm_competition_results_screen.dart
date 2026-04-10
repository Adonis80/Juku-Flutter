import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sm_competition.dart';
import '../state/sm_competition_notifier.dart';

/// Final results / leaderboard for a completed competition.
class SmCompetitionResultsScreen extends ConsumerWidget {
  final String competitionId;
  const SmCompetitionResultsScreen({super.key, required this.competitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(smCompetitionDetailProvider(competitionId));
    final theme = Theme.of(context);

    if (detail.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final comp = detail.competition;
    final entries = detail.entries;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                comp?.title ?? 'Results',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.tertiaryContainer,
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events,
                    size: 72,
                    color:
                        theme.colorScheme.onTertiaryContainer.withAlpha(60),
                  ),
                ),
              ),
            ),
          ),

          // Podium.
          if (entries.length >= 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _Podium(entries: entries.take(3).toList()),
              ),
            ),

          // Full leaderboard.
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final entry = entries[i];
                  return _ResultRow(
                    entry: entry,
                    position: i + 1,
                    xpFirst: comp?.xpFirst ?? 200,
                    xpSecond: comp?.xpSecond ?? 100,
                    xpThird: comp?.xpThird ?? 50,
                    xpParticipation: comp?.xpParticipation ?? 15,
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<SmCompetitionEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place.
        if (entries.length > 1) _PodiumSlot(entry: entries[1], place: 2),
        const SizedBox(width: 8),
        // 1st place.
        _PodiumSlot(entry: entries[0], place: 1),
        const SizedBox(width: 8),
        // 3rd place.
        if (entries.length > 2) _PodiumSlot(entry: entries[2], place: 3),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final SmCompetitionEntry entry;
  final int place;
  const _PodiumSlot({required this.entry, required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = place == 1 ? 120.0 : place == 2 ? 90.0 : 70.0;
    final avatarSize = place == 1 ? 48.0 : 36.0;
    final medalColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];

    return Column(
      children: [
        // Avatar.
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: medalColors[place - 1],
          child: CircleAvatar(
            radius: avatarSize / 2 - 3,
            backgroundImage: entry.translatorPhotoUrl != null
                ? NetworkImage(entry.translatorPhotoUrl!)
                : null,
            child: entry.translatorPhotoUrl == null
                ? Text(
                    (entry.translatorUsername ?? '?')[0].toUpperCase(),
                    style: TextStyle(fontSize: avatarSize / 3),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.translatorUsername ?? '?',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          entry.qualityScore.toStringAsFixed(1),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 4),
        // Podium bar.
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: medalColors[place - 1].withAlpha(60),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$place',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: medalColors[place - 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final SmCompetitionEntry entry;
  final int position;
  final int xpFirst;
  final int xpSecond;
  final int xpThird;
  final int xpParticipation;

  const _ResultRow({
    required this.entry,
    required this.position,
    required this.xpFirst,
    required this.xpSecond,
    required this.xpThird,
    required this.xpParticipation,
  });

  int get _xpEarned {
    if (position == 1) return xpFirst;
    if (position == 2) return xpSecond;
    if (position == 3) return xpThird;
    return xpParticipation;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '$position',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: position <= 3
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        title: Text(
          entry.translatorUsername ?? 'Anonymous',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${entry.qualityScore.toStringAsFixed(1)} avg / ${entry.totalVotes} votes',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+$_xpEarned XP',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            if (entry.prizeJuice > 0)
              Text(
                '+${entry.prizeJuice} Juice',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
