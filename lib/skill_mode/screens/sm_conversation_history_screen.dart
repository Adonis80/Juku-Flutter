import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/sm_conversation.dart';
import '../state/sm_conversation_state.dart';

/// Conversation history screen (GL-3).
class SmConversationHistoryScreen extends ConsumerWidget {
  const SmConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(conversationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: history.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No conversations yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final conv = list[index];
              return _HistoryCard(conversation: conv);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AiConversation conversation;

  const _HistoryCard({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overall = conversation.overallScore ?? 0;
    final grade = _gradeLabel(overall);
    final color = _gradeColor(overall);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Score circle.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(20),
              ),
              child: Center(
                child: Text(
                  conversation.status == 'completed' ? '$overall' : '—',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.scenario?.title ?? 'Free conversation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${conversation.turnCount} turns · ${_timeAgo(conversation.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                conversation.status == 'completed' ? grade : 'Abandoned',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),

            // XP.
            if (conversation.xpAwarded > 0) ...[
              const SizedBox(width: 8),
              Text(
                '+${conversation.xpAwarded}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _gradeLabel(int score) {
    if (score >= 90) return 'Outstanding';
    if (score >= 75) return 'Great';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Okay';
    return 'Needs work';
  }

  Color _gradeColor(int score) {
    if (score >= 90) return const Color(0xFFF59E0B);
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF6366F1);
    if (score >= 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
