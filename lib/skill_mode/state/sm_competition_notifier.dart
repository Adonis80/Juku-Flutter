import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sm_competition.dart';
import '../services/sm_competition_service.dart';

// ---------------------------------------------------------------------------
// Competition Hub (list all competitions)
// ---------------------------------------------------------------------------

class SmCompetitionHubState {
  final List<SmCompetition> active;
  final List<SmCompetition> voting;
  final List<SmCompetition> upcoming;
  final List<SmCompetition> completed;
  final bool loading;
  final String? error;

  const SmCompetitionHubState({
    this.active = const [],
    this.voting = const [],
    this.upcoming = const [],
    this.completed = const [],
    this.loading = true,
    this.error,
  });

  SmCompetitionHubState copyWith({
    List<SmCompetition>? active,
    List<SmCompetition>? voting,
    List<SmCompetition>? upcoming,
    List<SmCompetition>? completed,
    bool? loading,
    String? error,
  }) {
    return SmCompetitionHubState(
      active: active ?? this.active,
      voting: voting ?? this.voting,
      upcoming: upcoming ?? this.upcoming,
      completed: completed ?? this.completed,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class SmCompetitionHubNotifier extends Notifier<SmCompetitionHubState> {
  final _service = SmCompetitionService();

  @override
  SmCompetitionHubState build() {
    _load();
    return const SmCompetitionHubState();
  }

  Future<void> _load() async {
    try {
      final all = await _service.fetchCompetitions(
        statuses: ['active', 'voting', 'upcoming', 'completed'],
      );

      state = SmCompetitionHubState(
        active: all.where((c) => c.isActive).toList(),
        voting: all.where((c) => c.isVoting).toList(),
        upcoming: all.where((c) => c.isUpcoming).toList(),
        completed: all.where((c) => c.isCompleted).toList(),
        loading: false,
      );
    } catch (e) {
      state = SmCompetitionHubState(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    await _load();
  }
}

final smCompetitionHubProvider =
    NotifierProvider<SmCompetitionHubNotifier, SmCompetitionHubState>(
  SmCompetitionHubNotifier.new,
);

// ---------------------------------------------------------------------------
// Competition Detail (single competition + entries + votes)
// ---------------------------------------------------------------------------

class SmCompetitionDetailState {
  final SmCompetition? competition;
  final List<SmCompetitionEntry> entries;
  final SmCompetitionEntry? myEntry;
  final Map<String, int> myVotes;
  final bool loading;
  final String? error;

  const SmCompetitionDetailState({
    this.competition,
    this.entries = const [],
    this.myEntry,
    this.myVotes = const {},
    this.loading = true,
    this.error,
  });

  SmCompetitionDetailState copyWith({
    SmCompetition? competition,
    List<SmCompetitionEntry>? entries,
    SmCompetitionEntry? myEntry,
    Map<String, int>? myVotes,
    bool? loading,
    String? error,
  }) {
    return SmCompetitionDetailState(
      competition: competition ?? this.competition,
      entries: entries ?? this.entries,
      myEntry: myEntry ?? this.myEntry,
      myVotes: myVotes ?? this.myVotes,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Loads competition detail as a FutureProvider.family — auto-disposes.
final _smCompetitionDetailLoader =
    FutureProvider.family<SmCompetitionDetailState, String>(
        (ref, competitionId) async {
  final service = SmCompetitionService();
  final results = await Future.wait([
    service.fetchCompetition(competitionId),
    service.fetchEntries(competitionId),
    service.fetchMyEntry(competitionId),
    service.fetchMyVotes(competitionId),
  ]);

  return SmCompetitionDetailState(
    competition: results[0] as SmCompetition,
    entries: results[1] as List<SmCompetitionEntry>,
    myEntry: results[2] as SmCompetitionEntry?,
    myVotes: results[3] as Map<String, int>,
    loading: false,
  );
});

/// Combines loader + mutable override. Read this in widgets.
final smCompetitionDetailProvider =
    Provider.family<SmCompetitionDetailState, String>((ref, competitionId) {
  final async = ref.watch(_smCompetitionDetailLoader(competitionId));
  return async.when(
    data: (state) => state,
    loading: () => const SmCompetitionDetailState(),
    error: (e, _) =>
        SmCompetitionDetailState(loading: false, error: e.toString()),
  );
});

/// Helper for mutations (submit entry, vote). Invalidates the loader
/// after each mutation so the provider re-fetches.
class SmCompetitionDetailActions {
  final WidgetRef _ref;
  final String competitionId;
  final _service = SmCompetitionService();

  SmCompetitionDetailActions(this._ref, this.competitionId);

  Future<void> submitEntry({
    required List<SmEntryLine> translations,
    String? styleNote,
  }) async {
    await _service.submitEntry(
      competitionId: competitionId,
      translations: translations,
      styleNote: styleNote,
    );
    _ref.invalidate(_smCompetitionDetailLoader(competitionId));
  }

  Future<void> vote({
    required String entryId,
    required int score,
  }) async {
    await _service.vote(
      competitionId: competitionId,
      entryId: entryId,
      score: score,
    );
    _ref.invalidate(_smCompetitionDetailLoader(competitionId));
  }

  void refresh() {
    _ref.invalidate(_smCompetitionDetailLoader(competitionId));
  }
}
