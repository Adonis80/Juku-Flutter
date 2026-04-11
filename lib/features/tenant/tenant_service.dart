import '../../core/supabase_config.dart';

/// Data models for the tenant dashboard.

class TenantBranding {
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final String? welcomeMessage;

  const TenantBranding({
    this.logoUrl,
    this.primaryColor = '#7C3AED',
    this.secondaryColor = '#EC4899',
    this.welcomeMessage,
  });

  factory TenantBranding.fromJson(Map<String, dynamic> json) => TenantBranding(
        logoUrl: json['logo_url'] as String?,
        primaryColor: json['primary_color'] as String? ?? '#7C3AED',
        secondaryColor: json['secondary_color'] as String? ?? '#EC4899',
        welcomeMessage: json['welcome_message'] as String?,
      );
}

class Tenant {
  final String id;
  final String name;
  final String? slug;
  final String plan;
  final bool setupComplete;
  final String? customDomain;
  final TenantBranding branding;
  final DateTime createdAt;

  const Tenant({
    required this.id,
    required this.name,
    this.slug,
    this.plan = 'starter',
    this.setupComplete = false,
    this.customDomain,
    this.branding = const TenantBranding(),
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String?,
        plan: json['plan'] as String? ?? 'starter',
        setupComplete: json['setup_complete'] as bool? ?? false,
        customDomain: json['custom_domain'] as String?,
        branding: TenantBranding.fromJson(json),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class TenantAdmin {
  final String id;
  final String tenantId;
  final String userId;
  final String role;
  final DateTime createdAt;
  final String? username;
  final String? displayName;

  const TenantAdmin({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.username,
    this.displayName,
  });

  factory TenantAdmin.fromJson(Map<String, dynamic> json) => TenantAdmin(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        userId: json['user_id'] as String,
        role: json['role'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        username: (json['profiles'] as Map<String, dynamic>?)?['username']
            as String?,
        displayName:
            (json['profiles'] as Map<String, dynamic>?)?['display_name']
                as String?,
      );
}

class TenantInvite {
  final String id;
  final String tenantId;
  final String? email;
  final String inviteCode;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const TenantInvite({
    required this.id,
    required this.tenantId,
    this.email,
    required this.inviteCode,
    required this.role,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  factory TenantInvite.fromJson(Map<String, dynamic> json) => TenantInvite(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        email: json['email'] as String?,
        inviteCode: json['invite_code'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        acceptedAt: json['accepted_at'] != null
            ? DateTime.parse(json['accepted_at'] as String)
            : null,
      );
}

class TenantAnalytics {
  final String tenantId;
  final DateTime date;
  final int dau;
  final int totalPlays;
  final double juiceIn;
  final double juiceOut;
  final int newSignups;
  final int totalCards;

  const TenantAnalytics({
    required this.tenantId,
    required this.date,
    required this.dau,
    required this.totalPlays,
    required this.juiceIn,
    required this.juiceOut,
    required this.newSignups,
    required this.totalCards,
  });

  factory TenantAnalytics.fromJson(Map<String, dynamic> json) =>
      TenantAnalytics(
        tenantId: json['tenant_id'] as String,
        date: DateTime.parse(json['snapshot_date'] as String),
        dau: json['dau'] as int? ?? 0,
        totalPlays: json['total_plays'] as int? ?? 0,
        juiceIn: (json['juice_in'] as num?)?.toDouble() ?? 0,
        juiceOut: (json['juice_out'] as num?)?.toDouble() ?? 0,
        newSignups: json['new_signups'] as int? ?? 0,
        totalCards: json['total_cards'] as int? ?? 0,
      );
}

class ModerationItem {
  final String id;
  final String tenantId;
  final String cardId;
  final String cardType;
  final String cardTitle;
  final String submittedBy;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final String? submitterName;

  const ModerationItem({
    required this.id,
    required this.tenantId,
    required this.cardId,
    required this.cardType,
    required this.cardTitle,
    required this.submittedBy,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.submitterName,
  });

  factory ModerationItem.fromJson(Map<String, dynamic> json) => ModerationItem(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        cardId: json['card_id'] as String,
        cardType: json['card_type'] as String,
        cardTitle: json['card_title'] as String,
        submittedBy: json['submitted_by'] as String,
        status: json['status'] as String,
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        submitterName:
            (json['profiles'] as Map<String, dynamic>?)?['username']
                as String?,
      );
}

/// Service layer for all tenant dashboard operations.
class TenantService {
  TenantService._();
  static final instance = TenantService._();

  final _sb = supabase;

  // --- Tenant CRUD ---

  Future<Tenant?> getMyTenant() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;

    final adminRow = await _sb
        .from('tenant_admins')
        .select('tenant_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (adminRow == null) return null;

    final tenantId = adminRow['tenant_id'] as String;
    final row =
        await _sb.from('tenants').select().eq('id', tenantId).maybeSingle();
    if (row == null) return null;
    return Tenant.fromJson(row);
  }

  Future<Tenant> createTenant({
    required String name,
    required String slug,
    required String plan,
  }) async {
    final uid = _sb.auth.currentUser!.id;
    final row = await _sb.from('tenants').insert({
      'name': name,
      'slug': slug,
      'plan': plan,
    }).select().single();

    // Make creator the owner
    await _sb.from('tenant_admins').insert({
      'tenant_id': row['id'],
      'user_id': uid,
      'role': 'owner',
    });

    return Tenant.fromJson(row);
  }

  Future<void> updateBranding({
    required String tenantId,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    String? welcomeMessage,
  }) async {
    final updates = <String, dynamic>{};
    if (logoUrl != null) updates['logo_url'] = logoUrl;
    if (primaryColor != null) updates['primary_color'] = primaryColor;
    if (secondaryColor != null) updates['secondary_color'] = secondaryColor;
    if (welcomeMessage != null) updates['welcome_message'] = welcomeMessage;
    if (updates.isNotEmpty) {
      await _sb.from('tenants').update(updates).eq('id', tenantId);
    }
  }

  Future<void> completeSetup(String tenantId) async {
    await _sb
        .from('tenants')
        .update({'setup_complete': true}).eq('id', tenantId);
  }

  // --- User Management ---

  Future<List<TenantAdmin>> getTenantUsers(String tenantId) async {
    final rows = await _sb
        .from('tenant_admins')
        .select('*, profiles(username, display_name)')
        .eq('tenant_id', tenantId)
        .order('created_at');
    return rows.map((r) => TenantAdmin.fromJson(r)).toList();
  }

  Future<TenantInvite> createInvite({
    required String tenantId,
    String? email,
    String role = 'member',
  }) async {
    final uid = _sb.auth.currentUser!.id;
    final row = await _sb.from('tenant_invites').insert({
      'tenant_id': tenantId,
      'email': email,
      'role': role,
      'invited_by': uid,
    }).select().single();
    return TenantInvite.fromJson(row);
  }

  Future<List<TenantInvite>> getInvites(String tenantId) async {
    final rows = await _sb
        .from('tenant_invites')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);
    return rows.map((r) => TenantInvite.fromJson(r)).toList();
  }

  Future<void> revokeInvite(String inviteId) async {
    await _sb
        .from('tenant_invites')
        .update({'status': 'revoked'}).eq('id', inviteId);
  }

  Future<void> removeUser(String tenantId, String userId) async {
    await _sb
        .from('tenant_admins')
        .delete()
        .eq('tenant_id', tenantId)
        .eq('user_id', userId);
  }

  Future<String> acceptInvite(String inviteCode) async {
    final result = await _sb.rpc('accept_tenant_invite', params: {
      'p_invite_code': inviteCode,
    });
    return result as String;
  }

  // --- Moderation ---

  Future<List<ModerationItem>> getModerationQueue(String tenantId) async {
    final rows = await _sb
        .from('tenant_moderation_queue')
        .select('*, profiles!submitted_by(username)')
        .eq('tenant_id', tenantId)
        .eq('status', 'pending')
        .order('created_at');
    return rows.map((r) => ModerationItem.fromJson(r)).toList();
  }

  Future<void> moderateCard({
    required String itemId,
    required bool approve,
    String? reason,
  }) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('tenant_moderation_queue').update({
      'status': approve ? 'approved' : 'rejected',
      'reviewed_by': uid,
      'reviewed_at': DateTime.now().toIso8601String(),
      'rejection_reason': reason,
    }).eq('id', itemId);
  }

  // --- Analytics ---

  Future<List<TenantAnalytics>> getAnalytics(
    String tenantId, {
    int days = 30,
  }) async {
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await _sb
        .from('tenant_analytics_snapshots')
        .select()
        .eq('tenant_id', tenantId)
        .gte('snapshot_date', since.substring(0, 10))
        .order('snapshot_date');
    return rows.map((r) => TenantAnalytics.fromJson(r)).toList();
  }
}
