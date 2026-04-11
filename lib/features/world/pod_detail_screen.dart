import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'world_service.dart';
import 'world_state.dart';

/// Pod detail screen — shows users in a shared space with avatars and card drops.
class PodDetailScreen extends ConsumerStatefulWidget {
  final String zoneId;
  final String? zoneName;

  const PodDetailScreen({
    super.key,
    required this.zoneId,
    this.zoneName,
  });

  @override
  ConsumerState<PodDetailScreen> createState() => _PodDetailScreenState();
}

class _PodDetailScreenState extends ConsumerState<PodDetailScreen> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _enter();
  }

  Future<void> _enter() async {
    await WorldService.instance.enterPod(widget.zoneId);
    ref.invalidate(podMembersProvider(widget.zoneId));
    ref.invalidate(currentPodProvider);
    ref.invalidate(worldZonesProvider);
    setState(() => _entered = true);
  }

  Future<void> _leave() async {
    await WorldService.instance.leavePod();
    ref.invalidate(podMembersProvider(widget.zoneId));
    ref.invalidate(currentPodProvider);
    ref.invalidate(worldZonesProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(podMembersProvider(widget.zoneId));
    final dropsAsync = ref.watch(cardDropsProvider(widget.zoneId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zoneName ?? 'Pod'),
        actions: [
          TextButton.icon(
            onPressed: _leave,
            icon: const Icon(Icons.exit_to_app, size: 18),
            label: const Text('Leave'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pod space — shows avatars on a canvas
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerLowest,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant, width: 1),
              ),
              child: Stack(
                children: [
                  // Grid pattern
                  CustomPaint(
                    size: Size.infinite,
                    painter: _GridPainter(
                        color: theme.colorScheme.outlineVariant.withAlpha(50)),
                  ),

                  // Pod members as avatars
                  if (_entered)
                    membersAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (members) => _PodCanvas(members: members),
                    ),

                  // Card drops as floating orbs
                  dropsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (drops) => Stack(
                      children: [
                        for (final drop in drops)
                          Positioned(
                            left: drop.posX * 300,
                            top: drop.posY * 200,
                            child: _CardDropOrb(drop: drop),
                          ),
                      ],
                    ),
                  ),

                  // "You are here" indicator
                  if (_entered)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'You are here',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ),
                ],
              ),
            ),
          ),

          // Members list
          Expanded(
            flex: 2,
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (members) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${members.length} online',
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () =>
                                _showDropCardDialog(context, ref),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Drop Card'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final m = members[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              child: Text(
                                (m.displayName ?? m.username ?? '?')[0]
                                    .toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            title: Text(
                              m.displayName ?? m.username ?? 'Unknown',
                              style: theme.textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              'Joined ${_timeAgo(m.joinedAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (index * 50).ms)
                              .slideX(begin: 0.03, end: 0);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _showDropCardDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drop a Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Card title',
                hintText: 'e.g. "German Greetings"',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'This card will float in the pod for 24 hours. Anyone can play it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await WorldService.instance.dropCard(
                zoneId: widget.zoneId,
                cardId: 'manual-${DateTime.now().millisecondsSinceEpoch}',
                cardTitle: titleCtrl.text.trim(),
              );
              ref.invalidate(cardDropsProvider(widget.zoneId));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Drop'),
          ),
        ],
      ),
    );
  }
}

/// Canvas showing pod members as positioned avatars.
class _PodCanvas extends StatelessWidget {
  final List<PodMember> members;

  const _PodCanvas({required this.members});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rng = Random(42); // Deterministic layout

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (var i = 0; i < members.length; i++)
              Positioned(
                left: (members[i].posX != 0
                        ? members[i].posX
                        : (rng.nextDouble() * 0.7 + 0.15)) *
                    constraints.maxWidth,
                top: (members[i].posY != 0
                        ? members[i].posY
                        : (rng.nextDouble() * 0.6 + 0.2)) *
                    constraints.maxHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        (members[i].displayName ??
                                members[i].username ??
                                '?')[0]
                            .toUpperCase(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        members[i].username ?? 'User',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: (i * 100).ms)
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 600.ms,
                    ),
              ),
          ],
        );
      },
    );
  }
}

/// Floating card drop orb.
class _CardDropOrb extends StatelessWidget {
  final CardDrop drop;

  const _CardDropOrb({required this.drop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(100),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.9, end: 1.1, duration: 1500.ms)
        .shimmer(duration: 2000.ms);
  }
}

/// Grid pattern painter for the pod space.
class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => color != old.color;
}
