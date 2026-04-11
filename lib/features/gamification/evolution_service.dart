import '../../core/supabase_config.dart';

/// Evolution branch configuration.
enum EvolutionBranch {
  pronunciation(
    emoji: '\u{1F3B5}',
    label: 'Pronunciation',
    color1: 0xFF3B82F6,
    color2: 0xFF93C5FD,
  ),
  vocabulary(
    emoji: '\u{1F4D6}',
    label: 'Vocabulary',
    color1: 0xFF8B5CF6,
    color2: 0xFFC4B5FD,
  ),
  grammar(
    emoji: '\u{2699}\u{FE0F}',
    label: 'Grammar',
    color1: 0xFF22C55E,
    color2: 0xFF86EFAC,
  ),
  listening(
    emoji: '\u{1F442}',
    label: 'Listening',
    color1: 0xFFF97316,
    color2: 0xFFFDBA74,
  );

  const EvolutionBranch({
    required this.emoji,
    required this.label,
    required this.color1,
    required this.color2,
  });

  final String emoji;
  final String label;
  final int color1;
  final int color2;
}

/// Evolution stage names.
const evolutionStageNames = [
  'Egg',      // 0
  'Hatchling', // 1 (L5)
  'Fledgling', // 2 (L15)
  'Guardian',  // 3 (L30)
  'Champion',  // 4 (L50)
  'Mythic',    // 5 (L100)
];

const evolutionStageLevels = [0, 5, 15, 30, 50, 100];

/// User's evolution state.
class EvolutionState {
  const EvolutionState({
    required this.branch,
    required this.stage,
  });

  final EvolutionBranch branch;
  final int stage;

  String get stageName =>
      stage < evolutionStageNames.length ? evolutionStageNames[stage] : 'Unknown';
}

/// Cosmetic variant model.
class JukumonVariant {
  const JukumonVariant({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    this.skillBranch,
    required this.juiceCost,
    required this.seasonal,
    this.visualData = const {},
    this.owned = false,
    this.equipped = false,
  });

  factory JukumonVariant.fromMap(Map<String, dynamic> map,
      {bool owned = false, bool equipped = false}) {
    return JukumonVariant(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rarity: map['rarity'] as String? ?? 'common',
      skillBranch: map['skill_branch'] as String?,
      juiceCost: map['juice_cost'] as int? ?? 0,
      seasonal: map['seasonal'] as bool? ?? false,
      visualData: map['visual_data'] as Map<String, dynamic>? ?? {},
      owned: owned,
      equipped: equipped,
    );
  }

  final String id;
  final String name;
  final String description;
  final String rarity;
  final String? skillBranch;
  final int juiceCost;
  final bool seasonal;
  final Map<String, dynamic> visualData;
  final bool owned;
  final bool equipped;
}

/// Service for Jukumon evolution system.
class EvolutionService {
  EvolutionService._();
  static final instance = EvolutionService._();

  /// Get user's current evolution state.
  Future<EvolutionState?> getEvolution(String userId) async {
    final data = await supabase
        .from('jukumon_evolutions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;

    final skillName = data['dominant_skill'] as String? ?? 'vocabulary';
    final branch = EvolutionBranch.values.firstWhere(
      (b) => b.name == skillName,
      orElse: () => EvolutionBranch.vocabulary,
    );

    return EvolutionState(
      branch: branch,
      stage: data['evolution_stage'] as int? ?? 0,
    );
  }

  /// Check evolution and trigger if milestone reached.
  /// Returns evolution result with evolved flag.
  Future<Map<String, dynamic>?> checkEvolution(int level) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final result = await supabase.rpc('check_evolution', params: {
      'p_user_id': user.id,
      'p_level': level,
    });

    return result as Map<String, dynamic>?;
  }

  /// Get available variants (with ownership status).
  Future<List<JukumonVariant>> getVariants() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final variants = await supabase.from('jukumon_variants').select().order('rarity');

    // Get user's owned variants
    final owned = await supabase
        .from('user_jukumon_variants')
        .select('variant_id, equipped')
        .eq('user_id', user.id);

    final ownedMap = <String, bool>{};
    for (final o in owned) {
      ownedMap[o['variant_id'] as String] = o['equipped'] as bool? ?? false;
    }

    return variants.map((v) {
      final id = v['id'] as String;
      return JukumonVariant.fromMap(
        v,
        owned: ownedMap.containsKey(id),
        equipped: ownedMap[id] ?? false,
      );
    }).toList();
  }

  /// Purchase a variant with Juice.
  Future<bool> purchaseVariant(String variantId) async {
    final result = await supabase.rpc('purchase_variant', params: {
      'p_variant_id': variantId,
    });
    return result == true;
  }

  /// Equip a variant (unequip others).
  Future<void> equipVariant(String variantId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Unequip all
    await supabase
        .from('user_jukumon_variants')
        .update({'equipped': false})
        .eq('user_id', user.id);

    // Equip selected
    await supabase
        .from('user_jukumon_variants')
        .update({'equipped': true})
        .eq('user_id', user.id)
        .eq('variant_id', variantId);
  }
}
