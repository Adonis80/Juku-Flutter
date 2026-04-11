import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import 'evolution_service.dart';

/// Full-screen evolution cinematic + variant shop.
class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  EvolutionState? _evolution;
  List<JukumonVariant> _variants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final evolution = await EvolutionService.instance.getEvolution(user.id);
    final variants = await EvolutionService.instance.getVariants();

    if (mounted) {
      setState(() {
        _evolution = evolution;
        _variants = variants;
        _loading = false;
      });
    }
  }

  Future<void> _purchaseVariant(JukumonVariant variant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buy ${variant.name}?'),
        content: Text('This will cost ${variant.juiceCost} Juice.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Buy (${variant.juiceCost}J)'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await EvolutionService.instance.purchaseVariant(variant.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${variant.name} unlocked!'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not enough Juice')));
      }
    }
  }

  Future<void> _equipVariant(JukumonVariant variant) async {
    await EvolutionService.instance.equipVariant(variant.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Jukumon Evolution')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildEvolutionCard(theme),
                  const SizedBox(height: 24),
                  _buildEvolutionPath(theme),
                  const SizedBox(height: 24),
                  _buildVariantShop(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildEvolutionCard(ThemeData theme) {
    final evo = _evolution;
    final branch = evo?.branch ?? EvolutionBranch.vocabulary;
    final stage = evo?.stage ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Jukumon display
            Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(branch.color1), Color(branch.color2)],
                    ),
                    boxShadow: stage >= 3
                        ? [
                            BoxShadow(
                              color: Color(
                                branch.color1,
                              ).withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      branch.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -8, duration: 1500.ms),
            const SizedBox(height: 16),
            Text(
              evo?.stageName ?? 'Egg',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(branch.color1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                branch.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(branch.color1),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Stage $stage / 5',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildEvolutionPath(ThemeData theme) {
    final currentStage = _evolution?.stage ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolution Path',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(6, (i) {
            final isReached = i <= currentStage;
            final isCurrent = i == currentStage;
            final name = evolutionStageNames[i];
            final level = evolutionStageLevels[i];

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReached
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      border: isCurrent
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isReached
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : Text(
                              '$level',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isReached
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVariantShop(ThemeData theme) {
    if (_variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variant Shop',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cosmetic variants for your Jukumon',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 12),
        ..._variants.map((variant) {
          final rarityColor = switch (variant.rarity) {
            'legendary' => Colors.amber,
            'epic' => Colors.purple,
            'rare' => Colors.blue,
            _ => theme.colorScheme.outline,
          };

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rarityColor.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    variant.visualData['emoji'] as String? ?? '\u{2728}',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(variant.name),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      variant.rarity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                variant.description,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: variant.owned
                  ? variant.equipped
                        ? Chip(
                            label: const Text(
                              'Equipped',
                              style: TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          )
                        : TextButton(
                            onPressed: () => _equipVariant(variant),
                            child: const Text(
                              'Equip',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                  : variant.juiceCost > 0
                  ? FilledButton.tonal(
                      onPressed: () => _purchaseVariant(variant),
                      child: Text(
                        '${variant.juiceCost}J',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }),
      ],
    );
  }
}

/// Full-screen evolution cinematic — shown when Jukumon evolves.
class EvolutionCinematicScreen extends StatefulWidget {
  const EvolutionCinematicScreen({
    super.key,
    required this.branch,
    required this.fromStage,
    required this.toStage,
  });

  final EvolutionBranch branch;
  final int fromStage;
  final int toStage;

  @override
  State<EvolutionCinematicScreen> createState() =>
      _EvolutionCinematicScreenState();
}

class _EvolutionCinematicScreenState extends State<EvolutionCinematicScreen> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    // Reveal after the build-up
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _revealed = true);
    });
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) GoRouter.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branch = widget.branch;
    final newName = widget.toStage < evolutionStageNames.length
        ? evolutionStageNames[widget.toStage]
        : 'Unknown';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _revealed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Revealed Jukumon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(branch.color1), Color(branch.color2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(branch.color1).withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        branch.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    newName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 8),
                  Text(
                    '${branch.label} Branch',
                    style: TextStyle(color: Color(branch.color2), fontSize: 16),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                ],
              )
            : // Build-up: white light expanding
              Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(8, 8),
                    duration: 1800.ms,
                    curve: Curves.easeIn,
                  )
                  .fadeOut(delay: 1600.ms, duration: 200.ms),
      ),
    );
  }
}
