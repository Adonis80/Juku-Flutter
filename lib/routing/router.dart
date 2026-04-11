import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/bookmarks/bookmarks_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_thread_screen.dart';
import '../features/circles/circles_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/feed/create_lesson_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/lesson_detail_screen.dart';
import '../features/invite/invite_screen.dart';
import '../features/challenge/challenge_result_screen.dart';
import '../features/challenge/challenge_screen.dart';
import '../features/challenge/challenge_service.dart';
import '../features/juice/juice_wallet_screen.dart';
import '../features/live/live_list_screen.dart';
import '../features/live/live_session_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/public_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/studio/join_game_screen.dart';
import '../features/studio/lobby_screen.dart';
import '../features/studio/module_builder_screen.dart';
import '../features/studio/multiplayer_game_screen.dart';
import '../features/studio/play_screen.dart';
import '../features/studio/publish_success_screen.dart';
import '../features/studio/studio_home_screen.dart';
import '../features/studio/template_picker_screen.dart';
import '../features/topics/topic_channel_screen.dart';
import '../features/topics/topic_list_screen.dart';
import '../features/world/world_builder_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../main.dart' show onboardingDone;
import '../skill_mode/skill_mode_router.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final isAuth = authStatus == AuthStatus.authenticated;
      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/signup';
      final isOnboarding = state.uri.path == '/onboarding';

      // Show onboarding on first launch.
      if (!onboardingDone && !isOnboarding) return '/onboarding';
      if (!isAuth && !isAuthRoute && !isOnboarding) return '/login';
      if (isAuth && (isAuthRoute || isOnboarding)) return '/feed';
      return null;
    },
    routes: [
      // Onboarding (shown once on first launch)
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),

      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const SignupScreen(),
      ),

      // App routes (with bottom nav shell)
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: FeedScreen(),
            ),
          ),
          GoRoute(
            path: '/topics',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: TopicListScreen(),
            ),
          ),
          GoRoute(
            path: '/studio',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: StudioHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Detail routes (push on top of shell)
      GoRoute(
        path: '/lesson/:id',
        builder: (_, state) => LessonDetailScreen(
          lessonId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/chat/:partnerId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatThreadScreen(
            partnerId: state.pathParameters['partnerId']!,
            partnerName: extra?['displayName'] as String? ??
                extra?['username'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) => PublicProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/topics/:topicKey',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TopicChannelScreen(
            topicKey: state.pathParameters['topicKey']!,
            channelName: extra?['name'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (_, _) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (_, _) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/invite',
        builder: (_, _) => const InviteScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, _) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (_, _) => const JuiceWalletScreen(),
      ),
      GoRoute(
        path: '/world',
        builder: (_, _) => const WorldBuilderScreen(),
      ),
      GoRoute(
        path: '/circles',
        builder: (_, _) => const CirclesScreen(),
      ),
      // Studio routes
      GoRoute(
        path: '/studio/new',
        builder: (_, _) => const TemplatePickerScreen(),
      ),
      GoRoute(
        path: '/studio/build/:templateType',
        builder: (_, state) => ModuleBuilderScreen(
          templateTypeParam: state.pathParameters['templateType']!,
        ),
      ),
      GoRoute(
        path: '/studio/play/:moduleId',
        builder: (_, state) => PlayScreen(
          moduleId: state.pathParameters['moduleId']!,
        ),
      ),
      GoRoute(
        path: '/studio/published/:moduleId',
        builder: (_, state) => PublishSuccessScreen(
          moduleId: state.pathParameters['moduleId']!,
        ),
      ),
      GoRoute(
        path: '/studio/lobby/:sessionId',
        builder: (_, state) => LobbyScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/studio/game/:sessionId',
        builder: (_, state) => MultiplayerGameScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/studio/join/:sessionId',
        builder: (_, state) => JoinGameScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/join/:sessionId',
        builder: (_, state) => JoinGameScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/create',
        builder: (_, _) => const CreateLessonScreen(),
      ),
      GoRoute(
        path: '/challenge',
        builder: (_, _) => const ChallengeScreen(),
      ),
      GoRoute(
        path: '/challenge/result',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChallengeResultScreen(
            challengeId: extra?['challengeId'] as String? ?? '',
            result: extra?['result'] as ChallengeResult?,
            correct: extra?['correct'] as bool?,
            score: extra?['score'] as int?,
            timeMs: extra?['timeMs'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/live',
        builder: (_, _) => const LiveListScreen(),
      ),
      GoRoute(
        path: '/live/:sessionId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LiveSessionScreen(
            sessionId: state.pathParameters['sessionId']!,
            isHost: extra?['isHost'] as bool? ?? false,
          );
        },
      ),

      // Skill Mode routes
      ...skillModeRoutes(),
    ],
  );
});
