import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/sm_competition.dart';
import '../state/sm_competition_notifier.dart';

/// Competition hub — lists active, voting, upcoming, and past competitions.
class SmCompetitionHubScreen extends ConsumerWidget {
  const SmCompetitionHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(smCompetitionHubProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation Battles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(smCompetitionHubProvider.notifier).refresh(),
          ),
        ],
      ),
      body: hub.loading
          ? const Center(child: CircularProgressIndicator())
          : hub.error != null
          ? Center(child: Text('Error: ${hub.error}'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(smCompetitionHubProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (hub.active.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Live Now',
                      icon: Icons.bolt,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    ...hub.active.map((c) => _CompetitionCard(competition: c)),
                    const SizedBox(height: 24),
                  ],
                  if (hub.voting.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Voting Open',
                      icon: Icons.how_to_vote,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 8),
                    ...hub.voting.map((c) => _CompetitionCard(competition: c)),
                    const SizedBox(height: 24),
                  ],
                  if (hub.upcoming.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Coming Soon',
                      icon: Icons.schedule,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    ...hub.upcoming.map(
                      (c) => _CompetitionCard(competition: c),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (hub.completed.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Past Battles',
                      icon: Icons.emoji_events,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    ...hub.completed.map(
                      (c) => _CompetitionCard(competition: c),
                    ),
                  ],
                  if (hub.active.isEmpty &&
                      hub.voting.isEmpty &&
                      hub.upcoming.isEmpty &&
                      hub.completed.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(
                              Icons.translate,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withAlpha(100),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No competitions yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Translation battles will appear here\nwhen creators launch them.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withAlpha(150),
                              ),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final SmCompetition competition;

  const _CompetitionCard({required this.competition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = competition;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/skill-mode/competition/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with status chip.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusChip(status: c.status),
                ],
              ),
              const SizedBox(height: 8),

              // Song info.
              if (c.songTitle != null)
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${c.songTitle} — ${c.songArtist ?? "Unknown"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Stats row.
              Row(
                children: [
                  _StatPill(
                    icon: Icons.people_outline,
                    label: '${c.entryCount}/${c.maxEntries}',
                  ),
                  const SizedBox(width: 12),
                  _StatPill(
                    icon: Icons.diamond_outlined,
                    label: '${c.prizePoolJuice} Juice',
                  ),
                  const Spacer(),
                  if (c.isActive)
                    _CountdownText(deadline: c.submissionDeadline),
                  if (c.isVoting) _CountdownText(deadline: c.votingDeadline),
                  if (c.isUpcoming) _CountdownText(deadline: c.startsAt),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('LIVE', Theme.of(context).colorScheme.error),
      'voting' => ('VOTING', Theme.of(context).colorScheme.tertiary),
      'upcoming' => ('SOON', Theme.of(context).colorScheme.secondary),
      'completed' => ('ENDED', Theme.of(context).colorScheme.onSurfaceVariant),
      _ => (status.toUpperCase(), Theme.of(context).colorScheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CountdownText extends StatefulWidget {
  final DateTime deadline;
  const _CountdownText({required this.deadline});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (mounted) {
      setState(() {
        _remaining = widget.deadline.difference(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_remaining.isNegative) {
      return Text('Ended', style: theme.textTheme.labelSmall);
    }

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final text = hours > 24
        ? '${_remaining.inDays}d left'
        : hours > 0
        ? '${hours}h ${minutes}m'
        : '${minutes}m';

    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: hours < 2 ? theme.colorScheme.error : null,
      ),
    );
  }
}
