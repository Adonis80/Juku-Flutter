import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tenant_state.dart';
import 'tenant_service.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/moderation_tab.dart';
import 'tabs/branding_tab.dart';
import 'tabs/settings_tab.dart';

/// Main tenant admin dashboard with 5 tabs.
class TenantDashboardScreen extends ConsumerWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantProvider);

    return tenantAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (tenant) {
        if (tenant == null) {
          return const Scaffold(
            body: Center(child: Text('No tenant found')),
          );
        }
        return _DashboardBody(tenant: tenant);
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Tenant tenant;

  const _DashboardBody({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tenant.name),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.shield), text: 'Moderation'),
              Tab(icon: Icon(Icons.palette), text: 'Branding'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AnalyticsTab(tenantId: tenant.id),
            UsersTab(tenantId: tenant.id),
            ModerationTab(tenantId: tenant.id),
            BrandingTab(tenant: tenant),
            SettingsTab(tenant: tenant),
          ],
        )
            .animate()
            .fadeIn(duration: 300.ms),
      ),
    );
  }
}
