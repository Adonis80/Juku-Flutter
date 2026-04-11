import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'referral_service.dart';
import 'referral_state.dart';

/// Referral hub: share code, view referred users, leaderboard.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Refer Friends'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Share'),
              Tab(text: 'My Referrals'),
              Tab(text: 'Leaderboard'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ShareTab(),
            _MyReferralsTab(),
            _LeaderboardTab(),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

class _ShareTab extends ConsumerWidget {
  const _ShareTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(referralCodeProvider);
    final statsAsync = ref.watch(referralStatsProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Invite a friend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You both get 50 Juice + 100 XP',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Referral code
              codeAsync.when(
                loading: () => const CircularProgressIndicator(
                    color: Colors.white),
                error: (_, _) =>
                    const Text('Error', style: TextStyle(color: Colors.white)),
                data: (code) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            code.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Code copied!')),
                              );
                            },
                            icon: const Icon(Icons.copy,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final text =
                              ReferralService.shareText(code);
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Share text copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Invite'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 24),

        // Stats
        statsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (stats) {
            final count = stats?.totalReferrals ?? 0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Friends invited',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: theme.dividerColor),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${count * 50}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Juice earned',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms);
          },
        ),

        const SizedBox(height: 16),

        // Milestones
        Text('Milestones', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _MilestoneRow(label: 'First referral', target: 1, icon: Icons.star),
        _MilestoneRow(
            label: '5 referrals', target: 5, icon: Icons.local_fire_department),
        _MilestoneRow(label: '10 referrals', target: 10, icon: Icons.diamond),
        _MilestoneRow(label: '25 referrals', target: 25, icon: Icons.military_tech),
        _MilestoneRow(
            label: '50 referrals — Mythic cosmetic',
            target: 50,
            icon: Icons.auto_awesome),
      ],
    );
  }
}

class _MilestoneRow extends ConsumerWidget {
  final String label;
  final int target;
  final IconData icon;

  const _MilestoneRow({
    required this.label,
    required this.target,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(referralStatsProvider);
    final count = switch (statsAsync) {
      AsyncData(:final value) => value?.totalReferrals ?? 0,
      _ => 0,
    };
    final reached = count >= target;
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: reached ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: reached ? null : theme.colorScheme.outline,
          decoration: reached ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: reached
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Text('$count/$target', style: theme.textTheme.bodySmall),
    );
  }
}

class _MyReferralsTab extends ConsumerWidget {
  const _MyReferralsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(myReferralsProvider);
    final theme = Theme.of(context);

    return referralsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (referrals) {
        if (referrals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No referrals yet',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Share your code to get started!',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: referrals.length,
          itemBuilder: (context, index) {
            final r = referrals[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (r.referredUsername ?? '?')[0].toUpperCase(),
                  ),
                ),
                title: Text(r.referredUsername ?? 'User'),
                subtitle: Text(
                  'Joined ${_formatDate(r.createdAt)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (r.juiceRewarded)
                      Chip(
                        label: const Text('+50 Juice'),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 10),
                      ),
                    const SizedBox(width: 4),
                    if (r.xpRewarded)
                      Chip(
                        label: const Text('+100 XP'),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (index * 60).ms)
                .slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(referralLeaderboardProvider);
    final theme = Theme.of(context);

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No referrals yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;

            final rankIcon = switch (rank) {
              1 => Icons.emoji_events,
              2 => Icons.emoji_events,
              3 => Icons.emoji_events,
              _ => null,
            };
            final rankColor = switch (rank) {
              1 => Colors.amber,
              2 => Colors.grey[400]!,
              3 => Colors.brown[300]!,
              _ => theme.colorScheme.onSurfaceVariant,
            };

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      rank <= 3 ? rankColor.withAlpha(50) : null,
                  child: rankIcon != null
                      ? Icon(rankIcon, color: rankColor, size: 20)
                      : Text('#$rank'),
                ),
                title: Text(
                    entry.displayName ?? entry.username ?? 'Unknown'),
                trailing: Text(
                  '${entry.totalReferrals} referrals',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (index * 40).ms)
                .slideX(begin: 0.03, end: 0);
          },
        );
      },
    );
  }
}
