import 'package:flutter_test/flutter_test.dart';
import 'package:juku/features/tenant/tenant_service.dart';

void main() {
  group('TenantBranding', () {
    test('fromJson parses all fields', () {
      final json = {
        'logo_url': 'https://example.com/logo.png',
        'primary_color': '#2563EB',
        'secondary_color': '#DC2626',
        'welcome_message': 'Welcome!',
      };
      final branding = TenantBranding.fromJson(json);
      expect(branding.logoUrl, 'https://example.com/logo.png');
      expect(branding.primaryColor, '#2563EB');
      expect(branding.secondaryColor, '#DC2626');
      expect(branding.welcomeMessage, 'Welcome!');
    });

    test('fromJson uses defaults for missing fields', () {
      final branding = TenantBranding.fromJson({});
      expect(branding.logoUrl, isNull);
      expect(branding.primaryColor, '#7C3AED');
      expect(branding.secondaryColor, '#EC4899');
      expect(branding.welcomeMessage, isNull);
    });
  });

  group('Tenant', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'abc-123',
        'name': 'Test Tenant',
        'slug': 'test-tenant',
        'plan': 'growth',
        'setup_complete': true,
        'custom_domain': 'learn.test.com',
        'primary_color': '#059669',
        'secondary_color': '#D97706',
        'logo_url': null,
        'welcome_message': 'Hello!',
        'created_at': '2026-04-11T10:00:00Z',
      };
      final tenant = Tenant.fromJson(json);
      expect(tenant.id, 'abc-123');
      expect(tenant.name, 'Test Tenant');
      expect(tenant.slug, 'test-tenant');
      expect(tenant.plan, 'growth');
      expect(tenant.setupComplete, true);
      expect(tenant.customDomain, 'learn.test.com');
      expect(tenant.branding.primaryColor, '#059669');
      expect(tenant.branding.welcomeMessage, 'Hello!');
    });

    test('fromJson uses defaults', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final tenant = Tenant.fromJson(json);
      expect(tenant.plan, 'starter');
      expect(tenant.setupComplete, false);
      expect(tenant.customDomain, isNull);
    });
  });

  group('TenantInvite', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'inv-1',
        'tenant_id': 't-1',
        'email': 'test@example.com',
        'invite_code': 'abc123',
        'role': 'admin',
        'status': 'pending',
        'invited_by': 'u-1',
        'created_at': '2026-04-11T10:00:00Z',
        'accepted_at': null,
      };
      final invite = TenantInvite.fromJson(json);
      expect(invite.id, 'inv-1');
      expect(invite.email, 'test@example.com');
      expect(invite.inviteCode, 'abc123');
      expect(invite.role, 'admin');
      expect(invite.status, 'pending');
      expect(invite.acceptedAt, isNull);
    });

    test('fromJson with accepted_at', () {
      final json = {
        'id': 'inv-2',
        'tenant_id': 't-1',
        'invite_code': 'def456',
        'role': 'member',
        'status': 'accepted',
        'invited_by': 'u-1',
        'created_at': '2026-04-11T10:00:00Z',
        'accepted_at': '2026-04-11T12:00:00Z',
      };
      final invite = TenantInvite.fromJson(json);
      expect(invite.status, 'accepted');
      expect(invite.acceptedAt, isNotNull);
    });
  });

  group('TenantAnalytics', () {
    test('fromJson parses numeric fields', () {
      final json = {
        'tenant_id': 't-1',
        'snapshot_date': '2026-04-11',
        'dau': 42,
        'total_plays': 1500,
        'juice_in': 350.5,
        'juice_out': 120.0,
        'new_signups': 8,
        'total_cards': 200,
      };
      final analytics = TenantAnalytics.fromJson(json);
      expect(analytics.dau, 42);
      expect(analytics.totalPlays, 1500);
      expect(analytics.juiceIn, 350.5);
      expect(analytics.juiceOut, 120.0);
      expect(analytics.newSignups, 8);
      expect(analytics.totalCards, 200);
    });

    test('fromJson handles null numeric fields', () {
      final json = {'tenant_id': 't-1', 'snapshot_date': '2026-04-11'};
      final analytics = TenantAnalytics.fromJson(json);
      expect(analytics.dau, 0);
      expect(analytics.totalPlays, 0);
      expect(analytics.juiceIn, 0);
      expect(analytics.juiceOut, 0);
    });
  });

  group('ModerationItem', () {
    test('fromJson parses with embedded profile', () {
      final json = {
        'id': 'mod-1',
        'tenant_id': 't-1',
        'card_id': 'card-1',
        'card_type': 'flash',
        'card_title': 'German Basics',
        'submitted_by': 'u-1',
        'status': 'pending',
        'rejection_reason': null,
        'created_at': '2026-04-11T10:00:00Z',
        'profiles': {'username': 'johndoe'},
      };
      final item = ModerationItem.fromJson(json);
      expect(item.cardTitle, 'German Basics');
      expect(item.cardType, 'flash');
      expect(item.status, 'pending');
      expect(item.submitterName, 'johndoe');
    });
  });

  group('TenantAdmin', () {
    test('fromJson parses with profile data', () {
      final json = {
        'id': 'ta-1',
        'tenant_id': 't-1',
        'user_id': 'u-1',
        'role': 'owner',
        'created_at': '2026-04-11T10:00:00Z',
        'profiles': {'username': 'admin_user', 'display_name': 'Admin User'},
      };
      final admin = TenantAdmin.fromJson(json);
      expect(admin.role, 'owner');
      expect(admin.username, 'admin_user');
      expect(admin.displayName, 'Admin User');
    });

    test('fromJson handles missing profile', () {
      final json = {
        'id': 'ta-2',
        'tenant_id': 't-1',
        'user_id': 'u-2',
        'role': 'moderator',
        'created_at': '2026-04-11T10:00:00Z',
      };
      final admin = TenantAdmin.fromJson(json);
      expect(admin.username, isNull);
      expect(admin.displayName, isNull);
    });
  });
}
