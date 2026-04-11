import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'tenant_state.dart';

const _tenantPlans = [
  ('starter', 'Starter', '£99/mo', 'Up to 50 users'),
  ('growth', 'Growth', '£199/mo', 'Up to 500 users'),
  ('enterprise', 'Enterprise', '£499/mo', 'Unlimited users'),
];

const _brandColors = [
  '#7C3AED',
  '#2563EB',
  '#059669',
  '#DC2626',
  '#D97706',
  '#7C2D12',
  '#BE185D',
  '#4338CA',
];

/// 5-step self-serve tenant onboarding wizard.
class TenantOnboardingScreen extends ConsumerStatefulWidget {
  const TenantOnboardingScreen({super.key});

  @override
  ConsumerState<TenantOnboardingScreen> createState() =>
      _TenantOnboardingScreenState();
}

class _TenantOnboardingScreenState
    extends ConsumerState<TenantOnboardingScreen> {
  int _step = 0;
  bool _creating = false;

  // Step 1: Name + slug
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();

  // Step 2: Plan
  String _plan = 'starter';

  // Step 3: Branding
  String _primaryColor = '#7C3AED';
  String _secondaryColor = '#EC4899';

  // Step 4: Welcome message
  final _welcomeCtrl = TextEditingController();

  // Step 5: Invite emails
  final _inviteCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _welcomeCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty &&
            _slugCtrl.text.trim().isNotEmpty;
      case 1:
      case 2:
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (_step < 4) {
      setState(() => _step++);
      return;
    }

    // Final step — create tenant and finish setup
    setState(() => _creating = true);

    final notifier = ref.read(tenantProvider.notifier);

    final tenant = await notifier.createTenant(
      name: _nameCtrl.text.trim(),
      slug: _slugCtrl.text.trim().toLowerCase(),
      plan: _plan,
    );

    await notifier.updateBranding(
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      welcomeMessage: _welcomeCtrl.text.trim().isNotEmpty
          ? _welcomeCtrl.text.trim()
          : null,
    );

    await notifier.completeSetup();

    if (mounted) {
      context.go('/tenant/dashboard');
    }

    // Ignore the value — tenant is used implicitly via state
    tenant.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Launch Your Community'),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: List.generate(5, (i) {
                final done = i <= _step;
                return Expanded(
                  child:
                      Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: done
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                          .animate(target: done ? 1 : 0)
                          .scaleX(
                            begin: 0,
                            end: 1,
                            alignment: Alignment.centerLeft,
                            duration: 300.ms,
                            curve: Curves.easeOut,
                          ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Step ${_step + 1} of 5',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),

          // Step content
          Expanded(
            child: AnimatedSwitcher(duration: 300.ms, child: _buildStep()),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canProceed && !_creating ? _next : null,
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_step == 4 ? 'Launch Community' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _StepName(
        key: const ValueKey(0),
        nameCtrl: _nameCtrl,
        slugCtrl: _slugCtrl,
        onChanged: () => setState(() {}),
      ),
      1 => _StepPlan(
        key: const ValueKey(1),
        selected: _plan,
        onSelected: (p) => setState(() => _plan = p),
      ),
      2 => _StepBranding(
        key: const ValueKey(2),
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        colors: _brandColors,
        onPrimaryChanged: (c) => setState(() => _primaryColor = c),
        onSecondaryChanged: (c) => setState(() => _secondaryColor = c),
      ),
      3 => _StepWelcome(key: const ValueKey(3), ctrl: _welcomeCtrl),
      4 => _StepInvite(key: const ValueKey(4), ctrl: _inviteCtrl),
      _ => const SizedBox.shrink(),
    };
  }
}

class _StepName extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController slugCtrl;
  final VoidCallback onChanged;

  const _StepName({
    super.key,
    required this.nameCtrl,
    required this.slugCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Name your community',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'This is what your members will see.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Community name',
            hintText: 'e.g. Berlin German Learners',
          ),
          onChanged: (_) {
            // Auto-generate slug from name
            slugCtrl.text = nameCtrl.text
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                .replaceAll(RegExp(r'^-|-$'), '');
            onChanged();
          },
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: slugCtrl,
          decoration: const InputDecoration(
            labelText: 'URL slug',
            prefixText: 'juku.pro/',
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

class _StepPlan extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _StepPlan({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text('Choose your plan', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 24),
        for (final (key, label, price, desc) in _tenantPlans) ...[
          Card(
            elevation: selected == key ? 4 : 1,
            color: selected == key
                ? theme.colorScheme.primaryContainer
                : theme.cardColor,
            child: ListTile(
              title: Text('$label — $price'),
              subtitle: Text(desc),
              trailing: selected == key
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () => onSelected(key),
            ),
          ).animate().fadeIn(
            delay: (100 * _tenantPlans.indexWhere((e) => e.$1 == key)).ms,
          ),
          const SizedBox(height: 8),
        ],
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

class _StepBranding extends StatelessWidget {
  final String primaryColor;
  final String secondaryColor;
  final List<String> colors;
  final ValueChanged<String> onPrimaryChanged;
  final ValueChanged<String> onSecondaryChanged;

  const _StepBranding({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.colors,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
  });

  Color _parse(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text('Brand your community', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Pick your primary and accent colours.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Live preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_parse(primaryColor), _parse(secondaryColor)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.school, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                'Your Community',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 24),
        Text('Primary colour', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ColorRow(
          colors: colors,
          selected: primaryColor,
          onSelected: onPrimaryChanged,
        ),
        const SizedBox(height: 16),
        Text('Accent colour', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ColorRow(
          colors: colors,
          selected: secondaryColor,
          onSelected: onSecondaryChanged,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

class _ColorRow extends StatelessWidget {
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((hex) {
        final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
        final color = Color(0xFF000000 | value);
        final isSelected = hex == selected;
        return GestureDetector(
          onTap: () => onSelected(hex),
          child: AnimatedContainer(
            duration: 200.ms,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withAlpha(128), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _StepWelcome extends StatelessWidget {
  final TextEditingController ctrl;

  const _StepWelcome({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text('Welcome message', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'This appears when new members join your community.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Welcome to our language learning community! We\'re glad you\'re here.',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

class _StepInvite extends StatelessWidget {
  final TextEditingController ctrl;

  const _StepInvite({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text('Invite your team', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Add email addresses of admins or moderators. You can invite members later from the dashboard.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'admin@example.com, mod@example.com',
            helperText:
                'Separate emails with commas. Optional — skip to launch.',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.rocket_launch, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your community will be live immediately after launch. You can customise everything from the dashboard.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}
