import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sm_card.dart';
import '../services/sm_supabase_service.dart';

/// Active card queue + SR scheduling for a session.
class SmDeckNotifier extends AsyncNotifier<List<SmCard>> {
  final _service = SmSupabaseService();

  @override
  Future<List<SmCard>> build() async {
    return [];
  }

  /// Load due cards for the current user and language.
  Future<void> loadDeck({
    required String userId,
    required String language,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.fetchDueCards(
          userId: userId,
          language: language,
        ));
  }
}

final smDeckProvider =
    AsyncNotifierProvider<SmDeckNotifier, List<SmCard>>(SmDeckNotifier.new);
