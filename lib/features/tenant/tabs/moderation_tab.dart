import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tenant_state.dart';
import '../tenant_service.dart';

/// Content moderation queue: approve/reject cards.
class ModerationTab extends ConsumerWidget {
  final String tenantId;

  const ModerationTab({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(moderationQueueProvider(tenantId));
    final theme = Theme.of(context);

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('All caught up!', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'No content pending review.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _ModerationCard(
              item: item,
              tenantId: tenantId,
            )
                .animate()
                .fadeIn(delay: (index * 80).ms)
                .slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }
}

class _ModerationCard extends ConsumerWidget {
  final ModerationItem item;
  final String tenantId;

  const _ModerationCard({required this.item, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.check, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.close, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Approve
          await TenantService.instance
              .moderateCard(itemId: item.id, approve: true);
          ref.invalidate(moderationQueueProvider(tenantId));
          return true;
        } else {
          // Reject — show reason dialog
          final reason = await _showRejectDialog(context);
          if (reason != null) {
            await TenantService.instance.moderateCard(
              itemId: item.id,
              approve: false,
              reason: reason,
            );
            ref.invalidate(moderationQueueProvider(tenantId));
            return true;
          }
          return false;
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      item.cardType,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.cardTitle,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted by ${item.submitterName ?? 'Unknown'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final reason = await _showRejectDialog(context);
                      if (reason != null) {
                        await TenantService.instance.moderateCard(
                          itemId: item.id,
                          approve: false,
                          reason: reason,
                        );
                        ref.invalidate(moderationQueueProvider(tenantId));
                      }
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      await TenantService.instance
                          .moderateCard(itemId: item.id, approve: true);
                      ref.invalidate(moderationQueueProvider(tenantId));
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showRejectDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Why is this content being rejected?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
