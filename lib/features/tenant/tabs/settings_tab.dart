import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../tenant_service.dart';

/// Tenant settings tab: plan, billing, domain config.
class SettingsTab extends StatelessWidget {
  final Tenant tenant;

  const SettingsTab({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final planLabel = switch (tenant.plan) {
      'starter' => 'Starter — £99/mo',
      'growth' => 'Growth — £199/mo',
      'enterprise' => 'Enterprise — £499/mo',
      _ => tenant.plan,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current plan
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Plan', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.diamond, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        planLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Plan upgrades coming soon via Juice Wallet',
                        ),
                      ),
                    );
                  },
                  child: const Text('Upgrade Plan'),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 0.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 16),

        // Billing
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Billing', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Next invoice'),
                  subtitle: const Text('Billing portal coming soon'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Payment method'),
                  subtitle: const Text('Managed via Juice Wallet'),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 16),

        // Custom domain
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Custom Domain', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                Text(
                  tenant.customDomain ?? 'No custom domain configured',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CNAME your subdomain to juku.pro to use a custom URL.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Custom domain setup coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.language, size: 18),
                  label: const Text('Configure Domain'),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 16),

        // Tenant info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community Info', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                _InfoRow(label: 'Name', value: tenant.name),
                _InfoRow(label: 'Slug', value: tenant.slug ?? '-'),
                _InfoRow(
                  label: 'Created',
                  value:
                      '${tenant.createdAt.day}/${tenant.createdAt.month}/${tenant.createdAt.year}',
                ),
                _InfoRow(label: 'ID', value: tenant.id.substring(0, 8)),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
