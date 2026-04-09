import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sm_translation.dart';
import '../services/sm_translation_service.dart';

/// State for translation list on a card or lyric line.
class SmTranslationState {
  final List<SmTranslation> translations;
  final Map<String, int> userVotes;
  final SmTranslatorStats? myStats;
  final bool loading;

  const SmTranslationState({
    this.translations = const [],
    this.userVotes = const {},
    this.myStats,
    this.loading = true,
  });

  SmTranslationState copyWith({
    List<SmTranslation>? translations,
    Map<String, int>? userVotes,
    SmTranslatorStats? myStats,
    bool? loading,
  }) {
    return SmTranslationState(
      translations: translations ?? this.translations,
      userVotes: userVotes ?? this.userVotes,
      myStats: myStats ?? this.myStats,
      loading: loading ?? this.loading,
    );
  }
}

/// Notifier for managing translation state.
class SmTranslationNotifier extends Notifier<SmTranslationState> {
  final _service = SmTranslationService();

  @override
  SmTranslationState build() => const SmTranslationState();

  Future<void> loadForCard({
    required String cardId,
    required String userId,
  }) async {
    state = state.copyWith(loading: true);
    final translations = await _service.getCardTranslations(cardId: cardId);
    final votes = translations.isNotEmpty
        ? await _service.getUserVotesBatch(
            translationIds: translations.map((t) => t.id).toList(),
            userId: userId,
          )
        : <String, int>{};
    final stats = await _service.getTranslatorStats(userId: userId);
    state = SmTranslationState(
      translations: translations,
      userVotes: votes,
      myStats: stats,
      loading: false,
    );
  }

  Future<void> loadForLyric({
    required String songId,
    required int lineIndex,
    required String userId,
  }) async {
    state = state.copyWith(loading: true);
    final translations = await _service.getLyricTranslations(
      songId: songId,
      lineIndex: lineIndex,
    );
    final votes = translations.isNotEmpty
        ? await _service.getUserVotesBatch(
            translationIds: translations.map((t) => t.id).toList(),
            userId: userId,
          )
        : <String, int>{};
    final stats = await _service.getTranslatorStats(userId: userId);
    state = SmTranslationState(
      translations: translations,
      userVotes: votes,
      myStats: stats,
      loading: false,
    );
  }
}

final smTranslationProvider =
    NotifierProvider<SmTranslationNotifier, SmTranslationState>(
  SmTranslationNotifier.new,
);
