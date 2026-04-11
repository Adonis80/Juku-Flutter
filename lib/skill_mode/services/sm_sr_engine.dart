import 'dart:math';

import '../models/sm_user_card.dart';

/// SM-2 spaced repetition algorithm for Skill Mode.
class SmSrEngine {
  /// Review a card and update its SR state.
  void reviewCard(
    SmUserCard card,
    int scorePct, {
    required bool hintUsed,
    required bool transformUsed,
  }) {
    if (hintUsed) {
      card.intervalDays = 1;
    } else if (transformUsed) {
      card.intervalDays = max(1, (card.intervalDays * 0.7).round());
    } else if (scorePct >= 70) {
      if (card.repetitions == 0) {
        card.intervalDays = 1;
      } else if (card.repetitions == 1) {
        card.intervalDays = 6;
      } else {
        card.intervalDays = (card.intervalDays * card.easeFactor).round();
      }
      card.easeFactor = (card.easeFactor + 0.1 - (0.08 * (1 - scorePct / 100)))
          .clamp(1.3, 2.5);
      card.repetitions++;
      card.masteryProven = !hintUsed && !transformUsed;
    } else {
      card.repetitions = 0;
      card.intervalDays = 1;
    }
    card.nextReviewAt = DateTime.now().add(Duration(days: card.intervalDays));
    card.lastScorePct = scorePct;
  }
}
