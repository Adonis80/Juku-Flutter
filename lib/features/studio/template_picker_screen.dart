import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Template')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TemplateCard(
            icon: Icons.psychology,
            name: 'Quiz',
            description: 'Test knowledge with multiple choice questions',
            example: 'German A1 vocabulary quiz',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.push('/studio/build/quiz'),
          ),
          const SizedBox(height: 12),
          _TemplateCard(
            icon: Icons.layers,
            name: 'Flashcard Battle',
            description: 'Flip cards to memorise anything',
            example: 'Japanese hiragana deck',
            color: const Color(0xFF06B6D4),
            onTap: () => context.push('/studio/build/flashcard'),
          ),
          const SizedBox(height: 12),
          _TemplateCard(
            icon: Icons.calculate,
            name: 'Price Calculator',
            description: 'Help customers understand your pricing',
            example: 'Tailoring alterations quote',
            color: const Color(0xFFF59E0B),
            onTap: () => context.push('/studio/build/calculator'),
          ),
          const SizedBox(height: 12),
          _TemplateCard(
            icon: Icons.account_tree,
            name: 'Smart Calculator',
            description: 'Guided step-by-step pricing with branching logic',
            example: 'Wedding dress alterations quoter',
            color: const Color(0xFF10B981),
            onTap: () => context.push('/studio/build/conditional_calculator'),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'More templates coming soon...',
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final String example;
  final Color color;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.icon,
    required this.name,
    required this.description,
    required this.example,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'e.g. "$example"',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
