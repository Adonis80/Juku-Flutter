import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthStatus>(AuthStateNotifier.new);

class AuthStateNotifier extends Notifier<AuthStatus> {
  StreamSubscription<AuthState>? _sub;

  @override
  AuthStatus build() {
    final session = supabase.auth.currentSession;
    final initial =
        session != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;

    _sub?.cancel();
    _sub = supabase.auth.onAuthStateChange.listen((data) {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          state = AuthStatus.authenticated;
        case AuthChangeEvent.signedOut:
          state = AuthStatus.unauthenticated;
        default:
          break;
      }
    });

    ref.onDispose(() => _sub?.cancel());

    return initial;
  }
}

final currentUserProvider = Provider<User?>((ref) {
  final status = ref.watch(authStateProvider);
  if (status != AuthStatus.authenticated) return null;
  return supabase.auth.currentUser;
});

/// Sign in with email & password
Future<String?> signInWithEmail(String email, String password) async {
  try {
    await supabase.auth.signInWithPassword(email: email, password: password);
    return null;
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

/// Sign up with email & password
Future<String?> signUpWithEmail(
  String email,
  String password,
  String username,
) async {
  try {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': username},
    );
    return null;
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

/// Sign in with Google OAuth
Future<void> signInWithGoogle() async {
  await supabase.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: kIsWeb ? null : 'pro.juku.app://callback',
  );
}

/// Sign out
Future<void> signOut() async {
  await supabase.auth.signOut();
}
