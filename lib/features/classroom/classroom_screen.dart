import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'classroom_service.dart';
import 'classroom_state.dart';

/// Main classroom hub: teacher's classes and joined classes.
class ClassroomScreen extends ConsumerWidget {
  const ClassroomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Classrooms'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Classes'),
              Tab(text: 'Joined'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Join by code',
              onPressed: () => _showJoinDialog(context, ref),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _TeacherTab(),
            _StudentTab(),
          ],
        ).animate().fadeIn(duration: 300.ms),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Create Class'),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String language = 'german';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Classroom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Class name',
                  hintText: 'e.g. German Year 9',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: language,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const [
                  DropdownMenuItem(value: 'german', child: Text('German')),
                  DropdownMenuItem(value: 'french', child: Text('French')),
                  DropdownMenuItem(value: 'russian', child: Text('Russian')),
                  DropdownMenuItem(value: 'arabic', child: Text('Arabic')),
                  DropdownMenuItem(
                      value: 'mandarin', child: Text('Mandarin')),
                ],
                onChanged: (v) => setDialogState(() => language = v!),
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
                if (nameCtrl.text.trim().isEmpty) return;
                await ClassroomService.instance.createClassroom(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : null,
                  language: language,
                );
                ref.invalidate(myClassroomsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Classroom'),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            labelText: 'Class code',
            hintText: 'Enter the 6-character code',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.none,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              try {
                await ClassroomService.instance
                    .joinClassroom(codeCtrl.text.trim());
                ref.invalidate(joinedClassroomsProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined classroom!')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _TeacherTab extends ConsumerWidget {
  const _TeacherTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(myClassroomsProvider);
    final theme = Theme.of(context);

    return classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (classes) {
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No classrooms yet',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Create a class to get started.',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final c = classes[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.school,
                      color: theme.colorScheme.primary),
                ),
                title: Text(c.name),
                subtitle: Text(
                  '${c.studentCount}/${c.maxStudents} students · ${c.language} · Code: ${c.joinCode}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy join code',
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: c.joinCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Code "${c.joinCode}" copied')),
                        );
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => context.push('/classroom/${c.id}',
                    extra: {'name': c.name}),
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

class _StudentTab extends ConsumerWidget {
  const _StudentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(joinedClassroomsProvider);
    final theme = Theme.of(context);

    return classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (classes) {
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_outlined,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('Not in any classes',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Ask your teacher for a join code.',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final c = classes[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.school,
                      color: theme.colorScheme.secondary),
                ),
                title: Text(c.name),
                subtitle: Text(
                  c.language,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/classroom/${c.id}',
                    extra: {'name': c.name}),
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
