import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../grammar_modules/sm_language_registry.dart';

/// Skill Mode home — language selector, daily count, streak, start session.
class SmHomeScreen extends ConsumerStatefulWidget {
  const SmHomeScreen({super.key});

  @override
  ConsumerState<SmHomeScreen> createState() => _SmHomeScreenState();
}

class _SmHomeScreenState extends ConsumerState<SmHomeScreen> {
  String _selectedLanguage = 'de';
  int _dueCards = 0;
  int _totalCards = 0;
  int _streakDays = 0;
  bool _loading = true;

  static final _languages = {
    for (final lang in SmLanguageRegistry.allLanguages)
      lang.code: (lang.name, lang.flag),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Count total cards for this language
      final cards = await supabase
          .from('skill_mode_cards')
          .select('id')
          .eq('language', _selectedLanguage);
      final totalCards = (cards as List).length;

      // Count due cards
      final dueCards = await supabase
          .from('skill_mode_user_cards')
          .select('id')
          .eq('user_id', user.id)
          .lte('next_review_at', DateTime.now().toIso8601String())
          .eq('suspended', false);
      final dueCount = (dueCards as List).length;

      // Get streak
      final langProgress = await supabase
          .from('skill_mode_user_languages')
          .select('streak_days')
          .eq('user_id', user.id)
          .eq('language', _selectedLanguage)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _totalCards = totalCards;
          // If user has no user_cards yet, show total available cards as "due"
          _dueCards = dueCount > 0 ? dueCount : totalCards;
          _streakDays = langProgress?['streak_days'] as int? ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langEntry = _languages[_selectedLanguage]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skill Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/feed'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language selector
                  Text(
                    'Language',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _languages.entries.map((entry) {
                        final isSelected = entry.key == _selectedLanguage;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text('${entry.value.$2} ${entry.value.$1}'),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedLanguage = entry.key);
                                _loadData();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Streak card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 40,
                            color: _streakDays > 0
                                ? Colors.orange
                                : theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_streakDays day streak',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _streakDays > 0
                                    ? 'Keep it going!'
                                    : 'Start your streak today',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daily card count
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.style,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_dueCards cards due today',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_totalCards total ${langEntry.$1} cards',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI Conversation Partner entry card (GL-3)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/skill/conversation'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.record_voice_over,
                              size: 40,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Conversation',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Practice speaking with a native AI partner',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Translation Battles entry card
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/skill-mode/competitions'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.translate,
                              size: 40,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Translation Battles',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Compete to translate song lyrics',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Empty state for new users
                  if (_totalCards == 0)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.rocket_launch_outlined,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No cards available yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Run the seed script to add German cards',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_totalCards > 0)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () => context.push('/skill-mode/deck'),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          _dueCards > 0
                              ? 'Start session'
                              : 'Your first session',
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
