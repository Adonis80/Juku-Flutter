/// Global app state flags set during startup.
///
/// Kept in a separate file to avoid circular imports between
/// main.dart, router.dart, and onboarding_screen.dart.

/// Whether onboarding has been completed. Set in main() from SharedPreferences.
/// Updated immediately when the user completes onboarding so the router
/// redirect sees the new value on the same navigation event.
bool onboardingDone = false;
