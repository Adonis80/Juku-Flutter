import 'package:go_router/go_router.dart';

import 'screens/sm_card_screen.dart';
import 'screens/sm_create_deck_screen.dart';
import 'screens/sm_creator_dashboard_screen.dart';
import 'screens/sm_creator_profile_screen.dart';
import 'screens/sm_deck_detail_screen.dart';
import 'screens/sm_deck_screen.dart';
import 'screens/sm_marketplace_screen.dart';
import 'screens/sm_home_screen.dart';
import 'screens/sm_pronunciation_screen.dart';
import 'screens/sm_shuffle_screen.dart';
import 'screens/sm_song_list_screen.dart';
import 'screens/sm_song_player_screen.dart';
import 'screens/sm_song_upload_screen.dart';
import 'screens/sm_challenge_screen.dart';
import 'screens/sm_conjugation_table_screen.dart';
import 'screens/sm_duo_battle_screen.dart';
import 'screens/sm_duo_lobby_screen.dart';
import 'screens/sm_duo_results_screen.dart';
import 'screens/sm_translation_screen.dart';
import 'screens/sm_vault_screen.dart';
import 'screens/sm_writing_screen.dart';

/// All GoRouter sub-routes for Skill Mode.
/// Added as detail routes (pushed on top of shell) in the main router.
List<GoRoute> skillModeRoutes() {
  return [
    GoRoute(
      path: '/skill-mode',
      builder: (_, _) => const SmHomeScreen(),
    ),
    GoRoute(
      path: '/skill-mode/create-deck',
      builder: (_, _) => const SmCreateDeckScreen(),
    ),
    GoRoute(
      path: '/skill-mode/marketplace',
      builder: (_, _) => const SmMarketplaceScreen(),
    ),
    GoRoute(
      path: '/skill-mode/deck',
      builder: (_, _) => const SmDeckScreen(),
    ),
    GoRoute(
      path: '/skill-mode/deck-detail/:id',
      builder: (_, state) => SmDeckDetailScreen(
        deckId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/card/:id',
      builder: (_, state) => SmCardScreen(
        cardId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/shuffle/:id',
      builder: (_, state) => SmShuffleScreen(
        cardId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/pronunciation/:id',
      builder: (_, state) => SmPronunciationScreen(
        cardId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/songs',
      builder: (_, _) => const SmSongListScreen(),
    ),
    GoRoute(
      path: '/skill-mode/songs/upload',
      builder: (_, _) => const SmSongUploadScreen(),
    ),
    GoRoute(
      path: '/skill-mode/songs/:id',
      builder: (_, state) => SmSongPlayerScreen(
        songId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/creator/:userId',
      builder: (_, state) => SmCreatorProfileScreen(
        userId: state.pathParameters['userId']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/my-decks',
      builder: (_, _) => const SmCreatorDashboardScreen(),
    ),
    GoRoute(
      path: '/skill-mode/translations',
      builder: (_, state) => SmTranslationScreen(
        cardId: state.uri.queryParameters['cardId'],
        songId: state.uri.queryParameters['songId'],
        lyricLineIndex: state.uri.queryParameters['lineIndex'] != null
            ? int.tryParse(state.uri.queryParameters['lineIndex']!)
            : null,
        sourceText: state.uri.queryParameters['sourceText'] ?? '',
      ),
    ),
    GoRoute(
      path: '/skill-mode/challenges',
      builder: (_, _) => const SmChallengeScreen(),
    ),
    GoRoute(
      path: '/skill-mode/conjugation',
      builder: (_, state) => SmConjugationTableScreen(
        verb: state.uri.queryParameters['verb'] ?? '',
        language: state.uri.queryParameters['language'] ?? 'de',
        conjugations: const {},
      ),
    ),
    GoRoute(
      path: '/skill-mode/duo',
      builder: (_, _) => const SmDuoLobbyScreen(),
    ),
    GoRoute(
      path: '/skill-mode/duo-battle/:id',
      builder: (_, state) => SmDuoBattleScreen(
        battleId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/duo-results/:id',
      builder: (_, state) => SmDuoResultsScreen(
        battleId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/writing',
      builder: (_, state) => SmWritingScreen(
        character: state.uri.queryParameters['character'] ?? '',
        pinyin: state.uri.queryParameters['pinyin'],
        meaning: state.uri.queryParameters['meaning'] ?? '',
        language: state.uri.queryParameters['language'] ?? 'zh',
      ),
    ),
    GoRoute(
      path: '/skill-mode/vault',
      builder: (_, _) => const SmVaultScreen(),
    ),
  ];
}
