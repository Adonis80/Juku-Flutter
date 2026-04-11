import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'classroom_service.dart';
import 'classroom_state.dart';

/// Teacher's classroom detail with students, content, and class leaderboard.
class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;
  final String? className;

  const ClassroomDetailScreen({
    super.key,
    required this.classroomId,
    this.className,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(className ?? 'Classroom'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Students'),
              Tab(icon: Icon(Icons.library_books), text: 'Content'),
              Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StudentsTab(classroomId: classroomId),
            _ContentTab(classroomId: classroomId),
            _LeaderboardTab(classroomId: classroomId),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final String classroomId;

  const _StudentsTab({required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(classroomStudentsProvider(classroomId));
    final theme = Theme.of(context);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No students yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Share the join code with your students.',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final s = students[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (s.displayName ?? s.username ?? '?')[0].toUpperCase(),
                  ),
                ),
                title: Text(s.displayName ?? s.username ?? 'Unknown'),
                subtitle: Text(
                  'Joined ${_formatDate(s.joinedAt)} · ${s.role}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: s.role != 'teacher'
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 20),
                        onPressed: () async {
                          await ClassroomService.instance
                              .removeStudent(classroomId, s.userId);
                          ref.invalidate(
                              classroomStudentsProvider(classroomId));
                        },
                      )
                    : null,
              ),
            )
                .animate()
                .fadeIn(delay: (index * 50).ms)
                .slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _ContentTab extends ConsumerWidget {
  final String classroomId;

  const _ContentTab({required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(classroomContentProvider(classroomId));
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _showAssignDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Assign Content'),
          ),
        ),
        Expanded(
          child: contentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (content) {
              if (content.isEmpty) {
                return Center(
                  child: Text(
                    'No content assigned yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: content.length,
                itemBuilder: (context, index) {
                  final c = content[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.library_books),
                      title: Text(c.moduleTitle),
                      subtitle: Text(
                        c.dueDate != null
                            ? 'Due: ${c.dueDate!.day}/${c.dueDate!.month}/${c.dueDate!.year}'
                            : 'No due date',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (index * 50).ms)
                      .slideX(begin: 0.05, end: 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Content'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Module title',
            hintText: 'e.g. "German Greetings Deck"',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ClassroomService.instance.assignContent(
                classroomId: classroomId,
                moduleId: 'manual-${DateTime.now().millisecondsSinceEpoch}',
                moduleTitle: titleCtrl.text.trim(),
              );
              ref.invalidate(classroomContentProvider(classroomId));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final String classroomId;

  const _LeaderboardTab({required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(classroomStudentsProvider(classroomId));
    final theme = Theme.of(context);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('No students to rank'));
        }

        // Simple alphabetical leaderboard placeholder
        // In production, this would query XP data per student
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final s = students[index];
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
                title: Text(s.displayName ?? s.username ?? 'Student'),
                subtitle: Text(
                  'Joined ${s.joinedAt.day}/${s.joinedAt.month}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
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
