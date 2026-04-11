import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tenant_service.dart';

/// Current user's tenant (null if not a tenant admin).
final tenantProvider = AsyncNotifierProvider<TenantNotifier, Tenant?>(
  TenantNotifier.new,
);

class TenantNotifier extends AsyncNotifier<Tenant?> {
  @override
  Future<Tenant?> build() => TenantService.instance.getMyTenant();

  Future<Tenant> createTenant({
    required String name,
    required String slug,
    required String plan,
  }) async {
    final tenant = await TenantService.instance.createTenant(
      name: name,
      slug: slug,
      plan: plan,
    );
    state = AsyncData(tenant);
    return tenant;
  }

  Future<void> updateBranding({
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    String? welcomeMessage,
  }) async {
    final tenant = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (tenant == null) return;
    await TenantService.instance.updateBranding(
      tenantId: tenant.id,
      logoUrl: logoUrl,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      welcomeMessage: welcomeMessage,
    );
    ref.invalidateSelf();
  }

  Future<void> completeSetup() async {
    final tenant = switch (state) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (tenant == null) return;
    await TenantService.instance.completeSetup(tenant.id);
    ref.invalidateSelf();
  }
}

/// Tenant users list.
final tenantUsersProvider = FutureProvider.family<List<TenantAdmin>, String>(
  (ref, tenantId) => TenantService.instance.getTenantUsers(tenantId),
);

/// Tenant invites list.
final tenantInvitesProvider = FutureProvider.family<List<TenantInvite>, String>(
  (ref, tenantId) => TenantService.instance.getInvites(tenantId),
);

/// Moderation queue.
final moderationQueueProvider =
    FutureProvider.family<List<ModerationItem>, String>(
      (ref, tenantId) => TenantService.instance.getModerationQueue(tenantId),
    );

/// Analytics (last 30 days).
final tenantAnalyticsProvider =
    FutureProvider.family<List<TenantAnalytics>, String>(
      (ref, tenantId) => TenantService.instance.getAnalytics(tenantId),
    );
