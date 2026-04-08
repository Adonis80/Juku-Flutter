# CLAUDE.md — Juku Flutter

## What This Project Is

Juku Flutter is the mobile-first app for **Juku** — a gamified, user-generated knowledge network for language learners. This is the production app. The existing Next.js web app (in the `Juku` repo) serves as the marketing/discovery surface only.

Both apps share the same **Supabase** backend — all tables, RLS policies, RPCs, and realtime subscriptions work identically.

---

## Commands

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze         # Static analysis — must pass with zero issues
flutter test            # Run tests
flutter run             # Run on connected device/simulator
flutter build ios       # Build iOS release
flutter build apk       # Build Android APK
```

Before every commit: `flutter analyze` must pass with zero issues.

---

## Tech Stack

- **Flutter 3.41.6** (Dart 3.11.4)
- **Supabase Flutter** — auth, database, realtime
- **Riverpod 3** — state management (Notifier pattern, no StateNotifier)
- **GoRouter** — declarative routing with auth redirect
- **Google Fonts** — Inter as primary typeface
- **Flutter Animate** — micro-animations
- **Cached Network Image** — image loading

---

## Architecture

### Folder Structure
```
lib/
  core/           — supabase config, constants, shared utilities
  theme/          — app theme (light/dark, Material 3)
  routing/        — GoRouter config, app shell with bottom nav
  features/       — feature modules, each with screens + logic
    auth/         — login, signup, auth state (Riverpod)
    feed/         — lesson feed (pulls from Supabase)
    profile/      — user profile, stats
    lesson/       — lesson detail, create, edit
    chat/         — messaging (Supabase Realtime)
    gamification/ — XP, levels, ranks, streaks, Jukumon
    world/        — World Builder (objects, pods, cosmetics)
```

### State Management
- **Riverpod 3** with `Notifier` / `AsyncNotifier` (NOT `StateNotifier` — removed in v3)
- Auth state: `NotifierProvider<AuthStateNotifier, AuthStatus>`
- Data providers: `FutureProvider` or `AsyncNotifierProvider` wrapping Supabase queries

### Routing
- **GoRouter** with `ShellRoute` for bottom nav
- Auth guard via `redirect:` — unauthenticated users go to `/login`
- Deep link scheme: `pro.juku.app://callback` for OAuth

### Supabase
- URL and anon key in `lib/core/supabase_config.dart`
- Same database as Next.js app — all tables, RLS, RPCs shared
- Realtime for chat only; polling for dashboard stats

---

## Supabase Backend (Shared with Next.js)

- **URL:** `https://tipinjxdupfwntmkarkj.supabase.co`
- **Key tables:** profiles, lessons, follows, blocks, messages, topic_messages, xp_events, notifications, juice_wallets, juice_transactions, lesson_boosts, xp_multipliers, tips, learning_pods, world_objects, jukumon_cosmetics, user_cosmetics, builder_xp
- **RPCs:** spend_juice, award_xp, cast_lesson_vote, toggle_topic_message_vote, credit_tip
- **Auth:** Email/password + Google OAuth. Deep link: `pro.juku.app://callback`

---

## XP & Progression

Same rules as web app:
- Create lesson: +10 XP, Upvote received: +4 XP, Daily action: +5 XP
- Levels 1–10: 100 XP/level; 11–30: 250 XP/level; 31+: 500 XP/level
- Ranks: Bronze (L1) → Silver (L10) → Gold (L25) → Diamond (L50) → Mythic (L100)

---

## Code Style

- Dart analysis: zero issues
- No `print()` in production code — use `debugPrint()` only in debug
- Const constructors everywhere possible
- Named parameters preferred
- Feature-based folder structure (not layer-based)
- One widget per file for non-trivial widgets

---

## Related Repos

- **Next.js web app:** `~/Documents/Claude/Projects/Juku/` (GitHub: Adonis80/Claude_Juku)
- **Supabase migrations:** `~/Documents/Claude/Projects/Juku/supabase/migrations/`
- **Shared docs:** PRODUCT.md, ARCHITECTURE.md, DECISIONS.md in the Juku repo
