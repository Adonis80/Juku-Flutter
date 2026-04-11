import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tenant_state.dart';
import '../tenant_service.dart';

/// Branding customisation tab with live preview.
class BrandingTab extends ConsumerStatefulWidget {
  final Tenant tenant;

  const BrandingTab({super.key, required this.tenant});

  @override
  ConsumerState<BrandingTab> createState() => _BrandingTabState();
}

class _BrandingTabState extends ConsumerState<BrandingTab> {
  late String _primaryColor;
  late String _secondaryColor;
  late TextEditingController _welcomeCtrl;
  bool _saving = false;

  static const _colors = [
    '#7C3AED',
    '#2563EB',
    '#059669',
    '#DC2626',
    '#D97706',
    '#7C2D12',
    '#BE185D',
    '#4338CA',
    '#0D9488',
    '#4F46E5',
  ];

  @override
  void initState() {
    super.initState();
    _primaryColor = widget.tenant.branding.primaryColor;
    _secondaryColor = widget.tenant.branding.secondaryColor;
    _welcomeCtrl = TextEditingController(
      text: widget.tenant.branding.welcomeMessage,
    );
  }

  @override
  void dispose() {
    _welcomeCtrl.dispose();
    super.dispose();
  }

  Color _parse(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(tenantProvider.notifier)
        .updateBranding(
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
          welcomeMessage: _welcomeCtrl.text.trim().isNotEmpty
              ? _welcomeCtrl.text.trim()
              : null,
        );
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Branding saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live preview
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_parse(_primaryColor), _parse(_secondaryColor)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Mock phone frame
              Container(
                width: 200,
                height: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _parse(_primaryColor),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.tenant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 8,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 8,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: _parse(_secondaryColor).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _parse(_secondaryColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.home, color: _parse(_primaryColor)),
                          Icon(Icons.search, color: Colors.grey[400]),
                          Icon(Icons.person, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 24),

        // Primary colour
        Text('Primary colour', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((hex) {
            final isSelected = hex == _primaryColor;
            return GestureDetector(
              onTap: () => setState(() => _primaryColor = hex),
              child: AnimatedContainer(
                duration: 200.ms,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parse(hex),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _parse(hex).withAlpha(128),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Secondary colour
        Text('Accent colour', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((hex) {
            final isSelected = hex == _secondaryColor;
            return GestureDetector(
              onTap: () => setState(() => _secondaryColor = hex),
              child: AnimatedContainer(
                duration: 200.ms,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parse(hex),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _parse(hex).withAlpha(128),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Welcome message
        Text('Welcome message', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _welcomeCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Welcome to our community!',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        // Save button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Branding'),
          ),
        ),
      ],
    );
  }
}
