import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'world_service.dart';
import 'world_state.dart';

/// Main World Builder screen with 4 tabs: Pods, Objects, Card Drops, Gifts.
class WorldBuilderScreen extends ConsumerWidget {
  const WorldBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(worldJuiceProvider);
    final theme = Theme.of(context);

    final balance = switch (balanceAsync) {
      AsyncData(:final value) => value,
      _ => 0,
    };

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Juku World'),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$balance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.groups), text: 'Pods'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Objects'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'Card Drops'),
              Tab(icon: Icon(Icons.card_giftcard), text: 'Gifts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_PodsTab(), _ObjectsTab(), _CardDropsTab(), _GiftsTab()],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

/// Pods tab — shows language pods with presence counts, tap to enter.
class _PodsTab extends ConsumerWidget {
  const _PodsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(worldZonesProvider);
    final currentPodAsync = ref.watch(currentPodProvider);
    final theme = Theme.of(context);

    final currentPodId = switch (currentPodAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return zonesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (zones) {
        if (zones.isEmpty) {
          return const Center(child: Text('No pods available'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: zones.length,
          itemBuilder: (context, index) {
            final zone = zones[index];
            final isInThisPod = currentPodId == zone.id;

            final ambientIcon = switch (zone.language) {
              'german' => Icons.local_bar,
              'french' => Icons.local_cafe,
              'russian' => Icons.auto_stories,
              'arabic' => Icons.mosque,
              'mandarin' => Icons.park,
              _ => Icons.public,
            };

            return Card(
              color: isInThisPod
                  ? theme.colorScheme.primaryContainer
                  : theme.cardColor,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isInThisPod
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    ambientIcon,
                    color: isInThisPod
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(zone.name),
                subtitle: Text(
                  '${zone.presentCount}/${zone.maxCapacity} online · ${zone.language}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: isInThisPod
                    ? OutlinedButton(
                        onPressed: () async {
                          await WorldService.instance.leavePod();
                          ref.invalidate(worldZonesProvider);
                          ref.invalidate(currentPodProvider);
                        },
                        child: const Text('Leave'),
                      )
                    : FilledButton(
                        onPressed: () {
                          context.push(
                            '/world/pod/${zone.id}',
                            extra: {'zoneName': zone.name},
                          );
                        },
                        child: const Text('Enter'),
                      ),
              ),
            ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }
}

/// Objects tab — catalog of purchasable world objects.
class _ObjectsTab extends ConsumerWidget {
  const _ObjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(worldCatalogProvider);
    final balanceAsync = ref.watch(worldJuiceProvider);
    final theme = Theme.of(context);

    final balance = switch (balanceAsync) {
      AsyncData(:final value) => value,
      _ => 0,
    };

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (objects) {
        if (objects.isEmpty) {
          return const Center(child: Text('No objects available'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: objects.length,
          itemBuilder: (context, index) {
            final obj = objects[index];
            final canAfford = balance >= obj.juiceCost;

            return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: obj.seasonal
                                ? Colors.amber.withAlpha(50)
                                : theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            obj.seasonal ? 'SEASONAL' : obj.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: obj.seasonal
                                  ? Colors.amber[800]
                                  : theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          obj.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (obj.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            obj.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${obj.juiceCost}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 28,
                              child: FilledButton(
                                onPressed: canAfford
                                    ? () async {
                                        await WorldService.instance
                                            .purchaseObject(
                                              obj.id,
                                              obj.juiceCost,
                                            );
                                        ref.invalidate(worldJuiceProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Purchased ${obj.name}!',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: const Text('Buy'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: (index * 50).ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                );
          },
        );
      },
    );
  }
}

/// Card drops tab — shows active card drops across all zones.
class _CardDropsTab extends ConsumerWidget {
  const _CardDropsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPodAsync = ref.watch(currentPodProvider);
    final theme = Theme.of(context);

    final currentPodId = switch (currentPodAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };

    if (currentPodId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('Enter a pod first', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Card drops are visible inside pods.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    final dropsAsync = ref.watch(cardDropsProvider(currentPodId));

    return dropsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (drops) {
        if (drops.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('No card drops yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Be the first to drop a card!',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: drops.length,
          itemBuilder: (context, index) {
            final drop = drops[index];
            final remaining = drop.timeRemaining;
            final hoursLeft = remaining.inHours;

            return Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(drop.cardTitle),
                subtitle: Text(
                  'By ${drop.dropperName ?? 'Unknown'} · ${drop.playCount} plays · ${hoursLeft}h left',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing "${drop.cardTitle}"...')),
                    );
                  },
                  child: const Text('Play'),
                ),
              ),
            ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }
}

/// Gifts tab — incoming object gifts.
class _GiftsTab extends ConsumerWidget {
  const _GiftsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<List<ObjectGift>>(
      future: WorldService.instance.getMyGifts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final gifts = snapshot.data ?? [];

        if (gifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text('No gifts yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Friends can gift you world objects.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: gifts.length,
          itemBuilder: (context, index) {
            final gift = gifts[index];
            return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.card_giftcard),
                    ),
                    title: Text('Gift from ${gift.fromUsername ?? 'Someone'}'),
                    subtitle: gift.message != null
                        ? Text(gift.message!)
                        : const Text('A world object gift!'),
                    trailing: FilledButton(
                      onPressed: () async {
                        await WorldService.instance.claimGift(gift.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gift claimed!')),
                          );
                        }
                      },
                      child: const Text('Claim'),
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
}
