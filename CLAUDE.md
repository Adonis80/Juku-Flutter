# CLAUDE.md — Juku Flutter

## What This Project Is

Juku Flutter is the **production mobile app** for Juku — a gamified, user-generated knowledge network for language learners. This is the primary active codebase. The Next.js web app (`~/Documents/Claude/Projects/Juku/`) is the marketing surface only — maintenance mode.

Both apps share the same **Supabase** backend.

---

## Session Start Commands

**Double-click to run on iPhone (USB):**
```
~/Documents/Claude/Projects/Juku-Flutter/run-on-iphone.command
```

**Start Claude Code autonomous session (run in macOS Terminal):**
```bash
~/Documents/Claude/Projects/Juku/start-juku.sh
```
This auto-restarts on usage limits. Dhayan connects from iPhone: Claude app → Code tab.

---

## Commands

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze         # Static analysis — must pass with zero issues before commit
flutter test            # Run tests
flutter run             # Run on connected device/simulator
flutter build ios       # Build iOS release
flutter build apk       # Build Android APK
```

---

## Sprint Status

**All engineering sprints complete: Sprints 0–24 + SM-0 through SM-14 + Sprint 23.5**

| Sprint | What | Status |
|---|---|---|
| 0–24 | Core app, gamification, social, Studio MVP | ✅ DONE |
| SM-0–SM-14 | Skill Mode: tiles, audio, XP, duels, challenges, writing, competitions, polish | ✅ DONE |
| 23.5 | Gamified play overhauls, branding editor, image upload, cover art | ✅ DONE |
| **SM-15** | **Payment v2: Stripe + GoCardless** | **🔄 CURRENT** |

---

## Payment Credentials (obtained 2026-04-10)

- **Stripe:** pk_live + sk_live obtained ✅
- **GoCardless:** Juku SM-15 access token obtained ✅
- **Cloudflare R2:** juku-skill-mode token created 2026-04-09 ✅

See DECISIONS.md D-001 for full SM-15 payment architecture spec.

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
  skill_mode/     — 105 files, sm_ prefix, full Skill Mode engine
    grammar_modules/ — German, French, Russian, Arabic, Mandarin
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
- **Skill Mode tables (20 live):** skill_mode_modules, skill_mode_cards, skill_mode_sessions, skill_mode_progress, skill_mode_decks, skill_mode_deck_cards, skill_mode_deck_purchases, skill_mode_audio_files, skill_mode_community_translations, skill_mode_translation_votes, skill_mode_duo_battles, skill_mode_battle_moves, skill_mode_challenges, skill_mode_conjugation_tables, skill_mode_earnable_items, skill_mode_user_items, skill_mode_song_competitions, skill_mode_competition_entries, skill_mode_competition_votes, skill_mode_writing_attempts
- **RPCs:** spend_juice, award_xp, cast_lesson_vote, toggle_topic_message_vote, credit_tip
- **Auth:** Email/password + Google OAuth. Deep link: `pro.juku.app://callback`

---

## XP & Progression

- Create lesson: +10 XP, Upvote received: +4 XP, Daily action: +5 XP
- Levels 1–10: 100 XP/level; 11–30: 250 XP/level; 31+: 500 XP/level
- Ranks: Bronze (L1) → Silver (L10) → Gold (L25) → Diamond (L50) → Mythic (L100)

---

## Manual Tasks Remaining

- ⏳ Run seed script: `dart scripts/seed_skill_mode.dart`
- ⏳ Add R2 credentials to `.env`: Cloudflare dashboard → R2 → API tokens
- ⏳ Create Azure Speech resource + `supabase secrets set AZURE_SPEECH_KEY=[key]`
- ⏳ ElevenLabs: `supabase secrets set ELEVENLABS_API_KEY=[key]`
- ⏳ Run Sprint 23.5 Studio migration (`create_studio.sql`)
- ⏳ Deploy latest web code to Vercel (Sprints 9.8–19)
- ⏳ Test Google OAuth e2e on juku.pro
- ⏳ Apple Developer ($99/yr) — pay once Juice revenue covers it
- ⏳ App icon design (manual/designer)
- ⏳ Sound pack audio sourcing from freesound.org (Sprint 23.5.6)
- ⏳ Supabase Storage bucket `studio-images` (manual in Supabase dashboard)

---

## Code Style

- Dart analysis: zero issues (`flutter analyze`)
- No `print()` in production code — use `debugPrint()` only in debug
- Const constructors everywhere possible
- Named parameters preferred
- Feature-based folder structure (not layer-based)
- One widget per file for non-trivial widgets

---

## Related Repos

- **Next.js web app:** `~/Documents/Claude/Projects/Juku/` (GitHub: Adonis80/Claude_Juku) — maintenance only
- **Supabase migrations:** `~/Documents/Claude/Projects/Juku-Flutter/supabase/migrations/`
- **Shared docs:** PRODUCT.md, ARCHITECTURE.md, DECISIONS.md in this repo
- **Builder system:** `~/Documents/Claude/Projects/The-Builder/` (HANDOVER.md, BUILDER_SYSTEM.md)

---

## Cashflow Dashboard

Live at: https://dapper-chimera-40bd96.netlify.app
Source: `~/Documents/Claude/Projects/The-Builder/juku-cashflow.html`
