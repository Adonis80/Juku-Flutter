import 'package:go_router/go_router.dart';

import 'screens/sm_card_screen.dart';
import 'screens/sm_deck_screen.dart';
import 'screens/sm_home_screen.dart';
import 'screens/sm_shuffle_screen.dart';
import 'screens/sm_song_list_screen.dart';
import 'screens/sm_song_player_screen.dart';
import 'screens/sm_vault_screen.dart';

/// All GoRouter sub-routes for Skill Mode.
/// Added as detail routes (pushed on top of shell) in the main router.
List<GoRoute> skillModeRoutes() {
  return [
    GoRoute(
      path: '/skill-mode',
      builder: (_, _) => const SmHomeScreen(),
    ),
    GoRoute(
      path: '/skill-mode/deck',
      builder: (_, _) => const SmDeckScreen(),
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
      path: '/skill-mode/songs',
      builder: (_, _) => const SmSongListScreen(),
    ),
    GoRoute(
      path: '/skill-mode/songs/:id',
      builder: (_, state) => SmSongPlayerScreen(
        songId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/skill-mode/vault',
      builder: (_, _) => const SmVaultScreen(),
    ),
  ];
}
