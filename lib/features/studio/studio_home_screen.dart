import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'studio_state.dart';

class StudioHomeScreen extends ConsumerWidget {
  const StudioHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myModules = ref.watch(myModulesProvider);
    final communityModules = ref.watch(communityModulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Juku Studio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/studio/revenue'),
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Revenue',
          ),
          FilledButton.icon(
            onPressed: () => context.push('/studio/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Module'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(myModulesProvider.notifier).refresh();
          await ref.read(communityModulesProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // My Modules section
            Text(
              'My Modules',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            myModules.when(
              loading: () => _buildSkeletonList(),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading modules: $e'),
                ),
              ),
              data: (modules) => modules.isEmpty
                  ? _buildEmptyState(context, theme)
                  : Column(
                      children: modules
                          .map(
                            (m) => _ModuleCard(
                              module: m,
                              isOwn: true,
                              onTap: () {
                                if (m.published) {
                                  context.push('/studio/play/${m.id}');
                                }
                              },
                              onDelete: () =>
                                  _confirmDelete(context, ref, m.id),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // Community Modules section
            Text(
              'Community Modules',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            communityModules.when(
              loading: () => _buildSkeletonList(),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e'),
                ),
              ),
              data: (modules) => modules.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No community modules yet. Be the first!',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: modules
                          .map(
                            (m) => _ModuleCard(
                              module: m,
                              isOwn: false,
                              onTap: () => context.push('/studio/play/${m.id}'),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.auto_fix_high,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Build your first module',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create quizzes, flashcard decks, or calculators — powered by AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/studio/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create Module'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String moduleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete module?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(myModulesProvider.notifier).deleteModule(moduleId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final StudioModule module;
  final bool isOwn;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ModuleCard({
    required this.module,
    required this.isOwn,
    this.onTap,
    this.onDelete,
  });

  IconData _templateIcon(StudioTemplate t) {
    switch (t) {
      case StudioTemplate.quiz:
        return Icons.psychology;
      case StudioTemplate.flashcard:
        return Icons.layers;
      case StudioTemplate.calculator:
        return Icons.calculate;
      case StudioTemplate.conditionalCalculator:
        return Icons.account_tree;
    }
  }

  Color _rankColor(String? rank) {
    switch (rank) {
      case 'mythic':
        return const Color(0xFFFF6B6B);
      case 'diamond':
        return const Color(0xFF00BCD4);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCover = module.coverUrl != null && module.coverUrl!.isNotEmpty;
    final hasBranding = module.branding.isNotEmpty;

    // Build background decoration from branding
    BoxDecoration? coverDecoration;
    if (hasCover) {
      coverDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(module.coverUrl!),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.5),
            BlendMode.darken,
          ),
        ),
      );
    } else if (hasBranding) {
      coverDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseHex(module.primaryColor),
            _parseHex(module.accentColor),
          ],
        ),
      );
    }

    final useWhiteText = hasCover || hasBranding;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: isOwn ? onDelete : null,
        child: Container(
          decoration: coverDecoration,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: useWhiteText
                      ? Colors.white.withValues(alpha: 0.2)
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _templateIcon(module.templateType),
                  color: useWhiteText
                      ? Colors.white
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: useWhiteText ? Colors.white : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: useWhiteText
                                ? Colors.white.withValues(alpha: 0.2)
                                : theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            module.templateType.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: useWhiteText
                                  ? Colors.white
                                  : theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        if (!isOwn && module.creatorUsername != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '@${module.creatorUsername}',
                            style: TextStyle(
                              fontSize: 11,
                              color: useWhiteText
                                  ? Colors.white70
                                  : _rankColor(module.creatorRank),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isOwn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: module.published
                            ? Colors.green.withValues(alpha: 0.2)
                            : (useWhiteText
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        module.published ? 'Live' : 'Draft',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: module.published
                              ? (useWhiteText
                                    ? Colors.greenAccent
                                    : Colors.green)
                              : (useWhiteText
                                    ? Colors.white60
                                    : theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 14,
                        color: useWhiteText
                            ? Colors.white60
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${module.playCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: useWhiteText
                              ? Colors.white60
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
