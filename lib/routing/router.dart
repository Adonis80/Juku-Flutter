import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/profile/profile_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final isAuth = authStatus == AuthStatus.authenticated;
      final isAuthRoute = state.uri.path == '/login' ||
          state.uri.path == '/signup';

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
            path: '/explore',
            pageBuilder: (_, _) => NoTransitionPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Explore')),
                body: const Center(child: Text('Explore — coming soon')),
              ),
            ),
          ),
          GoRoute(
            path: '/create',
            pageBuilder: (_, _) => NoTransitionPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Create Lesson')),
                body: const Center(child: Text('Create — coming soon')),
              ),
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (_, _) => NoTransitionPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Chat')),
                body: const Center(child: Text('Chat — coming soon')),
              ),
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
    ],
  );
});
