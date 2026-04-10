import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_config.dart';

// --- Models ---

enum StudioTemplate { quiz, flashcard, calculator, conditionalCalculator }

extension StudioTemplateX on StudioTemplate {
  String get label {
    switch (this) {
      case StudioTemplate.quiz:
        return 'Quiz';
      case StudioTemplate.flashcard:
        return 'Flashcard Battle';
      case StudioTemplate.calculator:
        return 'Price Calculator';
      case StudioTemplate.conditionalCalculator:
        return 'Smart Calculator';
    }
  }

  String get dbValue {
    switch (this) {
      case StudioTemplate.conditionalCalculator:
        return 'conditional_calculator';
      default:
        return name;
    }
  }
}

StudioTemplate templateFromDb(String value) {
  switch (value) {
    case 'flashcard':
      return StudioTemplate.flashcard;
    case 'calculator':
      return StudioTemplate.calculator;
    case 'conditional_calculator':
      return StudioTemplate.conditionalCalculator;
    default:
      return StudioTemplate.quiz;
  }
}

class StudioModule {
  final String id;
  final String creatorId;
  final StudioTemplate templateType;
  final String title;
  final String? description;
  final Map<String, dynamic> config;
  final bool published;
  final int playCount;
  final String? domain;
  final DateTime? createdAt;
  final String? creatorUsername;
  final String? creatorRank;

  const StudioModule({
    required this.id,
    required this.creatorId,
    required this.templateType,
    required this.title,
    this.description,
    required this.config,
    required this.published,
    required this.playCount,
    this.domain,
    this.createdAt,
    this.creatorUsername,
    this.creatorRank,
  });

  factory StudioModule.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return StudioModule(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      templateType: templateFromDb(json['template_type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      config: json['config'] is String
          ? jsonDecode(json['config'] as String) as Map<String, dynamic>
          : json['config'] as Map<String, dynamic>? ?? {},
      published: json['published'] as bool? ?? false,
      playCount: json['play_count'] as int? ?? 0,
      domain: json['domain'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      creatorUsername: profile?['username'] as String?,
      creatorRank: profile?['rank'] as String?,
    );
  }
}

// --- Providers ---

final myModulesProvider =
    AsyncNotifierProvider<MyModulesNotifier, List<StudioModule>>(
        MyModulesNotifier.new);

class MyModulesNotifier extends AsyncNotifier<List<StudioModule>> {
  @override
  Future<List<StudioModule>> build() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('studio_modules')
        .select('*, profiles!studio_modules_creator_id_fkey(username, rank)')
        .eq('creator_id', user.id)
        .order('created_at', ascending: false);

    return (data as List).map((e) => StudioModule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> deleteModule(String moduleId) async {
    await supabase.from('studio_modules').delete().eq('id', moduleId);
    await refresh();
  }
}

final communityModulesProvider =
    AsyncNotifierProvider<CommunityModulesNotifier, List<StudioModule>>(
        CommunityModulesNotifier.new);

class CommunityModulesNotifier extends AsyncNotifier<List<StudioModule>> {
  @override
  Future<List<StudioModule>> build() async {
    final data = await supabase
        .from('studio_modules')
        .select('*, profiles!studio_modules_creator_id_fkey(username, rank)')
        .eq('published', true)
        .order('play_count', ascending: false)
        .limit(50);

    return (data as List).map((e) => StudioModule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final moduleByIdProvider =
    FutureProvider.family<StudioModule?, String>((ref, id) async {
  final data = await supabase
      .from('studio_modules')
      .select('*, profiles!studio_modules_creator_id_fkey(username, rank)')
      .eq('id', id)
      .maybeSingle();

  if (data == null) return null;
  return StudioModule.fromJson(data);
});

// --- Publish helper ---

Future<String> publishModule({
  required StudioTemplate templateType,
  required String title,
  String? description,
  required Map<String, dynamic> config,
  String? domain,
  Map<String, dynamic>? branding,
  String? coverUrl,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Not authenticated');

  final result = await supabase.from('studio_modules').insert({
    'creator_id': user.id,
    'template_type': templateType.dbValue,
    'title': title,
    'description': description,
    'config': config,
    'published': true,
    'domain': domain,
    if (branding != null) 'branding': branding,
    if (coverUrl != null) 'cover_url': coverUrl,
  }).select('id').single();

  // Award XP
  await supabase.from('xp_events').insert({
    'user_id': user.id,
    'event_type': 'studio_publish',
    'xp_amount': 20,
  });

  return result['id'] as String;
}

// --- Record play ---

Future<void> recordPlay({
  required String moduleId,
  int? score,
  required bool completed,
}) async {
  final user = supabase.auth.currentUser;

  await supabase.from('studio_plays').insert({
    'module_id': moduleId,
    'player_id': user?.id,
    'score': score,
    'completed': completed,
  });

  // Award XP to player
  if (user != null && completed) {
    await supabase.from('xp_events').insert({
      'user_id': user.id,
      'event_type': 'studio_play',
      'xp_amount': 2,
    });

    // Award XP to creator
    final module = await supabase
        .from('studio_modules')
        .select('creator_id')
        .eq('id', moduleId)
        .maybeSingle();

    if (module != null) {
      await supabase.from('xp_events').insert({
        'user_id': module['creator_id'] as String,
        'event_type': 'studio_creator_play',
        'xp_amount': 3,
      });
    }
  }
}
