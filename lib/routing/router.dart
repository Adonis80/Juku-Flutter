import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/bookmarks/bookmarks_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_thread_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/feed/create_lesson_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/lesson_detail_screen.dart';
import '../features/invite/invite_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/public_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/topics/topic_channel_screen.dart';
import '../features/topics/topic_list_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final isAuth = authStatus == AuthStatus.authenticated;
      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/signup';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/feed';
      return null;
    },
    routes: [
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
            path: '/create',
            pageBuilder: (_, _) => const NoTransitionPage(
              child: CreateLessonScreen(),
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
    ],
  );
});
