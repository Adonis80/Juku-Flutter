import 'package:flutter_riverpod/flutter_riverpod.dart';

/// XP, combo, streak tracking for the current Skill Mode session.
class SmSessionState {
  final int currentXp;
  final int combo;
  final int comboPeak;
  final int cardsReviewed;
  final int totalCards;
  final String? sessionId;

  const SmSessionState({
    this.currentXp = 0,
    this.combo = 0,
    this.comboPeak = 0,
    this.cardsReviewed = 0,
    this.totalCards = 0,
    this.sessionId,
  });

  double get comboMultiplier {
    if (combo >= 10) return 3.0;
    if (combo >= 5) return 2.0;
    if (combo >= 3) return 1.5;
    return 1.0;
  }

  SmSessionState copyWith({
    int? currentXp,
    int? combo,
    int? comboPeak,
    int? cardsReviewed,
    int? totalCards,
    String? sessionId,
  }) {
    return SmSessionState(
      currentXp: currentXp ?? this.currentXp,
      combo: combo ?? this.combo,
      comboPeak: comboPeak ?? this.comboPeak,
      cardsReviewed: cardsReviewed ?? this.cardsReviewed,
      totalCards: totalCards ?? this.totalCards,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class SmSessionNotifier extends Notifier<SmSessionState> {
  @override
  SmSessionState build() => const SmSessionState();

  void startSession({required String sessionId, required int totalCards}) {
    state = SmSessionState(sessionId: sessionId, totalCards: totalCards);
  }

  void addXp(int amount) {
    final adjusted = (amount * state.comboMultiplier).round();
    state = state.copyWith(currentXp: state.currentXp + adjusted);
  }

  void incrementCombo() {
    final newCombo = state.combo + 1;
    state = state.copyWith(
      combo: newCombo,
      comboPeak: newCombo > state.comboPeak ? newCombo : state.comboPeak,
    );
  }

  void breakCombo() {
    state = state.copyWith(combo: 0);
  }

  void advanceCard() {
    state = state.copyWith(cardsReviewed: state.cardsReviewed + 1);
  }
}

final smSessionProvider = NotifierProvider<SmSessionNotifier, SmSessionState>(
  SmSessionNotifier.new,
);
