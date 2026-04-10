import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/error_handler.dart';
import 'core/supabase_config.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'routing/router.dart';
import 'theme/app_theme.dart';

/// Whether onboarding has been shown. Set during startup.
bool onboardingDone = true;

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  setupErrorHandling();

  ErrorWidget.builder = (details) => AppErrorWidget(details: details);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  onboardingDone = await isOnboardingComplete();

  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: JukuApp()));
}

class JukuApp extends ConsumerWidget {
  const JukuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Juku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
