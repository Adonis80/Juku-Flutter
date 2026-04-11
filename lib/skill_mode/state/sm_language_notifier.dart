import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User's per-language progress (streak, badges, etc.).
class SmLanguageProgress {
  final String language;
  final int streakDays;
  final int streakFreezes;
  final DateTime? lastSessionAt;
  final List<String> unlockedBadges;

  const SmLanguageProgress({
    required this.language,
    this.streakDays = 0,
    this.streakFreezes = 0,
    this.lastSessionAt,
    this.unlockedBadges = const [],
  });
}

class SmLanguageNotifier extends AsyncNotifier<SmLanguageProgress?> {
  @override
  Future<SmLanguageProgress?> build() async {
    return null;
  }
}

final smLanguageProvider =
    AsyncNotifierProvider<SmLanguageNotifier, SmLanguageProgress?>(
      SmLanguageNotifier.new,
    );
