import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_state.dart';
import '../grammar_modules/sm_language_registry.dart';
import '../models/sm_conversation.dart';
import '../state/sm_conversation_state.dart';

/// Scenario picker for AI Conversation Partner (GL-3).
///
/// Shows available conversation scenarios for the selected language.
/// Level 10 gate — users must reach Level 10 to unlock.
class SmConversationScenariosScreen extends ConsumerStatefulWidget {
  const SmConversationScenariosScreen({super.key});

  @override
  ConsumerState<SmConversationScenariosScreen> createState() =>
      _SmConversationScenariosScreenState();
}

class _SmConversationScenariosScreenState
    extends ConsumerState<SmConversationScenariosScreen> {
  String _selectedLanguage = 'de';

  static final _languages = {
    for (final lang in SmLanguageRegistry.allLanguages)
      lang.code: (lang.name, lang.flag),
  };

  IconData _iconForName(String name) {
    return switch (name) {
      'flight' => Icons.flight,
      'restaurant' => Icons.restaurant,
      'work' => Icons.work,
      'hotel' => Icons.hotel,
      'local_hospital' => Icons.local_hospital,
      'shopping_cart' => Icons.shopping_cart,
      'directions' => Icons.directions,
      'phone' => Icons.phone,
      'coffee' => Icons.coffee,
      'emoji_food_beverage' => Icons.emoji_food_beverage,
      'chat' => Icons.chat,
      _ => Icons.chat_bubble_outline,
    };
  }

  Color _colorForDifficulty(String difficulty) {
    return switch (difficulty) {
      'beginner' => const Color(0xFF10B981),
      'intermediate' => const Color(0xFFF59E0B),
      'advanced' => const Color(0xFFEF4444),
      _ => const Color(0xFF6366F1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenarios =
        ref.watch(conversationScenariosProvider(_selectedLanguage));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Conversation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // History button.
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/skill/conversation/history'),
            tooltip: 'Conversation history',
          ),
          // API keys button.
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: () => context.push('/skill/conversation/keys'),
            tooltip: 'API keys',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language selector.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _languages.entries.map((entry) {
                  final isSelected = entry.key == _selectedLanguage;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${entry.value.$2} ${entry.value.$1}'),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedLanguage = entry.key);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Header.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Choose a scenario',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Practice real conversations with an AI native speaker',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Scenario list.
          Expanded(
            child: scenarios.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No scenarios available for this language yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final scenario = list[index];
                    return _ScenarioCard(
                      scenario: scenario,
                      icon: _iconForName(scenario.iconName),
                      color: _colorForDifficulty(scenario.difficulty),
                      onTap: () => _startConversation(scenario),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: index * 60),
                          duration: const Duration(milliseconds: 300),
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          delay: Duration(milliseconds: index * 60),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startConversation(ConversationScenario scenario) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(conversationProvider.notifier).startConversation(
          scenarioId: scenario.id,
          language: _selectedLanguage,
        );

    if (mounted) {
      context.push('/skill/conversation/live');
    }
  }
}

class _ScenarioCard extends StatelessWidget {
  final ConversationScenario scenario;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon circle.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),

              // Text.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scenario.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Difficulty badge.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scenario.difficulty[0].toUpperCase() +
                      scenario.difficulty.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
