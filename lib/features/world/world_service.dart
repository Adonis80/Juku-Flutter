import '../../core/supabase_config.dart';

/// Data models for Juku World v2.

class WorldZone {
  final String id;
  final String name;
  final String language;
  final String? description;
  final String ambientTheme;
  final int maxCapacity;
  final int presentCount;

  const WorldZone({
    required this.id,
    required this.name,
    required this.language,
    this.description,
    this.ambientTheme = 'default',
    this.maxCapacity = 20,
    this.presentCount = 0,
  });

  factory WorldZone.fromJson(Map<String, dynamic> json, {int present = 0}) =>
      WorldZone(
        id: json['id'] as String,
        name: json['name'] as String,
        language: json['language'] as String? ?? 'general',
        description: json['description'] as String?,
        ambientTheme: json['ambient_theme'] as String? ?? 'default',
        maxCapacity: json['max_capacity'] as int? ?? 20,
        presentCount: present,
      );
}

class PodMember {
  final String userId;
  final String? username;
  final String? displayName;
  final double posX;
  final double posY;
  final DateTime joinedAt;

  const PodMember({
    required this.userId,
    this.username,
    this.displayName,
    this.posX = 0,
    this.posY = 0,
    required this.joinedAt,
  });

  factory PodMember.fromJson(Map<String, dynamic> json) => PodMember(
    userId: json['user_id'] as String,
    username:
        (json['profiles'] as Map<String, dynamic>?)?['username'] as String?,
    displayName:
        (json['profiles'] as Map<String, dynamic>?)?['display_name'] as String?,
    posX: (json['position_x'] as num?)?.toDouble() ?? 0,
    posY: (json['position_y'] as num?)?.toDouble() ?? 0,
    joinedAt: DateTime.parse(json['joined_at'] as String),
  );
}

class WorldObject {
  final String id;
  final String name;
  final String? description;
  final String category;
  final int juiceCost;
  final String? iconUrl;
  final bool seasonal;
  final DateTime? availableUntil;

  const WorldObject({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.juiceCost,
    this.iconUrl,
    this.seasonal = false,
    this.availableUntil,
  });

  factory WorldObject.fromJson(Map<String, dynamic> json) => WorldObject(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    category: json['category'] as String? ?? 'decoration',
    juiceCost: json['juice_cost'] as int? ?? 0,
    iconUrl: json['icon_url'] as String?,
    seasonal: json['seasonal'] as bool? ?? false,
    availableUntil: json['available_until'] != null
        ? DateTime.parse(json['available_until'] as String)
        : null,
  );
}

class CardDrop {
  final String id;
  final String zoneId;
  final String droppedBy;
  final String? dropperName;
  final String cardId;
  final String cardTitle;
  final String cardType;
  final double posX;
  final double posY;
  final int playCount;
  final DateTime expiresAt;
  final DateTime createdAt;

  const CardDrop({
    required this.id,
    required this.zoneId,
    required this.droppedBy,
    this.dropperName,
    required this.cardId,
    required this.cardTitle,
    required this.cardType,
    this.posX = 0.5,
    this.posY = 0.5,
    this.playCount = 0,
    required this.expiresAt,
    required this.createdAt,
  });

  factory CardDrop.fromJson(Map<String, dynamic> json) => CardDrop(
    id: json['id'] as String,
    zoneId: json['zone_id'] as String,
    droppedBy: json['dropped_by'] as String,
    dropperName:
        (json['profiles'] as Map<String, dynamic>?)?['username'] as String?,
    cardId: json['card_id'] as String,
    cardTitle: json['card_title'] as String,
    cardType: json['card_type'] as String? ?? 'flash',
    posX: (json['position_x'] as num?)?.toDouble() ?? 0.5,
    posY: (json['position_y'] as num?)?.toDouble() ?? 0.5,
    playCount: json['play_count'] as int? ?? 0,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ObjectGift {
  final String id;
  final String objectId;
  final String fromUserId;
  final String toUserId;
  final String? fromUsername;
  final String? message;
  final bool claimed;
  final DateTime createdAt;

  const ObjectGift({
    required this.id,
    required this.objectId,
    required this.fromUserId,
    required this.toUserId,
    this.fromUsername,
    this.message,
    this.claimed = false,
    required this.createdAt,
  });

  factory ObjectGift.fromJson(Map<String, dynamic> json) => ObjectGift(
    id: json['id'] as String,
    objectId: json['object_id'] as String,
    fromUserId: json['from_user_id'] as String,
    toUserId: json['to_user_id'] as String,
    fromUsername:
        (json['from_profile'] as Map<String, dynamic>?)?['username'] as String?,
    message: json['message'] as String?,
    claimed: json['claimed'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// Service for all World v2 operations.
class WorldService {
  WorldService._();
  static final instance = WorldService._();

  final _sb = supabase;

  // --- Zones ---

  Future<List<WorldZone>> getZones() async {
    final zones = await _sb.from('vr_zones').select().order('name');

    // Get presence counts per zone
    final presence = await _sb.from('world_pod_presence').select('zone_id');
    final countMap = <String, int>{};
    for (final p in presence) {
      final zid = p['zone_id'] as String;
      countMap[zid] = (countMap[zid] ?? 0) + 1;
    }

    return zones
        .map(
          (z) =>
              WorldZone.fromJson(z, present: countMap[z['id'] as String] ?? 0),
        )
        .toList();
  }

  // --- Pod Presence ---

  Future<void> enterPod(String zoneId) async {
    final uid = _sb.auth.currentUser!.id;
    // Leave any existing pod first
    await _sb.from('world_pod_presence').delete().eq('user_id', uid);
    // Enter new pod
    await _sb.from('world_pod_presence').insert({
      'zone_id': zoneId,
      'user_id': uid,
    });
  }

  Future<void> leavePod() async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('world_pod_presence').delete().eq('user_id', uid);
  }

  Future<List<PodMember>> getPodMembers(String zoneId) async {
    final rows = await _sb
        .from('world_pod_presence')
        .select('*, profiles(username, display_name)')
        .eq('zone_id', zoneId)
        .order('joined_at');
    return rows.map((r) => PodMember.fromJson(r)).toList();
  }

  Future<String?> getCurrentPodId() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _sb
        .from('world_pod_presence')
        .select('zone_id')
        .eq('user_id', uid)
        .maybeSingle();
    return row?['zone_id'] as String?;
  }

  // --- Object Catalog ---

  Future<List<WorldObject>> getCatalog() async {
    final rows = await _sb
        .from('world_object_catalog')
        .select()
        .order('juice_cost', ascending: true);
    return rows.map((r) => WorldObject.fromJson(r)).toList();
  }

  Future<void> purchaseObject(String catalogId, int cost) async {
    await _sb.rpc(
      'spend_juice',
      params: {'p_amount': cost, 'p_reference': 'world_object:$catalogId'},
    );

    await _sb.from('world_objects').insert({
      'catalog_id': catalogId,
      'owner_id': _sb.auth.currentUser!.id,
    });

    // Increment purchase count
    await _sb.rpc(
      'increment_world_object_count',
      params: {'p_catalog_id': catalogId},
    );
  }

  // --- Card Drops ---

  Future<List<CardDrop>> getCardDrops(String zoneId) async {
    final rows = await _sb
        .from('world_card_drops')
        .select('*, profiles!dropped_by(username)')
        .eq('zone_id', zoneId)
        .order('created_at', ascending: false);
    return rows.map((r) => CardDrop.fromJson(r)).toList();
  }

  Future<void> dropCard({
    required String zoneId,
    required String cardId,
    required String cardTitle,
    String cardType = 'flash',
    double posX = 0.5,
    double posY = 0.5,
  }) async {
    await _sb.from('world_card_drops').insert({
      'zone_id': zoneId,
      'dropped_by': _sb.auth.currentUser!.id,
      'card_id': cardId,
      'card_title': cardTitle,
      'card_type': cardType,
      'position_x': posX,
      'position_y': posY,
    });
  }

  Future<void> playCardDrop(String dropId) async {
    await _sb
        .from('world_card_drops')
        .update({
          'play_count': _sb.from('world_card_drops').select('play_count'),
        })
        .eq('id', dropId);
    // Simple increment — in production use an RPC
  }

  // --- Object Gifting ---

  Future<void> giftObject({
    required String objectId,
    required String toUserId,
    String? message,
  }) async {
    await _sb.from('world_object_gifts').insert({
      'object_id': objectId,
      'from_user_id': _sb.auth.currentUser!.id,
      'to_user_id': toUserId,
      'message': message,
    });

    // Transfer ownership
    await _sb
        .from('world_objects')
        .update({'owner_id': toUserId})
        .eq('id', objectId);
  }

  Future<List<ObjectGift>> getMyGifts() async {
    final uid = _sb.auth.currentUser!.id;
    final rows = await _sb
        .from('world_object_gifts')
        .select()
        .eq('to_user_id', uid)
        .eq('claimed', false)
        .order('created_at', ascending: false);
    return rows.map((r) => ObjectGift.fromJson(r)).toList();
  }

  Future<void> claimGift(String giftId) async {
    await _sb
        .from('world_object_gifts')
        .update({'claimed': true})
        .eq('id', giftId);
  }

  // --- Juice Balance ---

  Future<int> getJuiceBalance() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 0;
    final row = await _sb
        .from('juice_wallets')
        .select('balance')
        .eq('user_id', uid)
        .maybeSingle();
    return (row?['balance'] as int?) ?? 0;
  }

  // --- Cosmetics ---

  Future<List<Map<String, dynamic>>> getCosmetics() async {
    return await _sb
        .from('jukumon_cosmetics')
        .select()
        .order('juice_cost', ascending: true);
  }
}
