# CLAUDE.md — Juku Flutter (v3.0)

**What this is:** Production Flutter mobile app for Juku — a gamified, user-generated knowledge network for language learners. Primary active codebase. The Next.js web app (`~/Documents/Claude/Projects/Juku/`) is marketing surface only — maintenance mode. Both share the same Supabase backend.

**GitHub:** https://github.com/Adonis80/Juku-Flutter

---

## Session Start

```bash
# Read these at the start of EVERY session — no exceptions:
~/Documents/Claude/Projects/The-Builder/HANDOVER.md
~/Documents/Claude/Projects/Juku-Flutter/SPRINT.md

# Run on iPhone (USB):
~/Documents/Claude/Projects/Juku-Flutter/run-on-iphone.command

# Start autonomous Claude Code session:
~/Documents/Claude/Projects/Juku/start-juku.sh
```

---

## Build Commands

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze --no-pub   # Static analysis — ZERO issues required before commit
flutter test --no-pub      # All tests — ZERO failures before commit
flutter run                # Run on connected device/simulator
dart format .              # Format all Dart files
flutter build ios          # iOS release build
flutter build apk          # Android APK
```

---

## NON-NEGOTIABLES — Violations = Task Failure

- **NEVER install a package** (`flutter pub add`, `dart pub add`) without explicit human approval via Dispatch
- **NEVER declare a task done** while `flutter analyze` has issues or `flutter test` has failures
- **NEVER mix business logic into widgets** — all logic goes in the repository or service layer
- **NEVER use `print()`** in production code — `debugPrint()` only inside debug blocks
- **NEVER access** `~/Library/Messages`, `~/Library/Contacts`, or any messaging database
- **NEVER force-push** to main (`git push --force` or `git push -f`)
- **ALWAYS run** `flutter analyze --no-pub` after any Dart file edit
- **ALWAYS write** unit tests for new gamification logic
- **ALWAYS write** session summary to HANDOVER.md at session end before exit
- **ALWAYS commit and push** to GitHub after each completed task
- **ALWAYS notify** Dhayan via Dispatch: `[JUKU] ✅ Task — one-line summary`
- **ALWAYS use** `⏳` in HANDOVER.md for pending manual tasks, `✅` when done

---

## Current Sprint

**GL-3: AI Conversation Partner** 🔄 CURRENT

All prior sprints complete:
| Range | What | Status |
|---|---|---|
| 0–24 | Core app, gamification, social, Studio MVP | ✅ |
| SM-0–SM-14 | Skill Mode: tiles, audio, XP, duels, challenges, writing, competitions, polish | ✅ |
| 23.5 | Gamified play overhauls, branding editor, image upload, cover art | ✅ |
| SM-15 | Payment v2: Stripe + GoCardless | ✅ |
| SM-16 | Juku Live: real-time broadcasts + gifting | ✅ |
| SM-17 | Daily Challenges: viral loop | ✅ |
| SM-18 | Jukumon Evolution v2 | ✅ |
| SM-19 | Juku Studio Pro | ✅ |
| SM-20 | White-Label Tenant Dashboard | ✅ |
| SM-21 | Juku World v2: Social Spaces | ✅ |
| SM-22 | App Store Launch Sprint | ✅ (code) |
| GL-1 | Referral Engine | ✅ |
| GL-2 | Juku for Schools | ✅ |

---

## Tech Stack

- **Flutter 3.41.6** (Dart 3.11.4)
- **Supabase Flutter** — auth, database, realtime
- **Riverpod 3** — state management. `Notifier`/`AsyncNotifier` ONLY. `StateNotifier` is removed in v3 — do NOT use it.
- **GoRouter** — declarative routing with auth redirect. `ShellRoute` for bottom nav. Auth guard via `redirect:`.
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
    feed/         — lesson feed (Supabase)
    profile/      — user profile, stats
    lesson/       — lesson detail, create, edit
    chat/         — messaging (Supabase Realtime)
    gamification/ — XP, levels, ranks, streaks, Jukumon
    world/        — World Builder (objects, pods, cosmetics)
  skill_mode/     — 105 files, sm_ prefix, full Skill Mode engine
    grammar_modules/ — German, French, Russian, Arabic, Mandarin
```

### State: Riverpod 3
- Auth: `NotifierProvider<AuthStateNotifier, AuthStatus>`
- Data: `FutureProvider` or `AsyncNotifierProvider` wrapping Supabase queries

### Routing
- GoRouter with ShellRoute for bottom nav
- Auth guard via `redirect:` — unauthenticated → `/login`
- Deep link: `pro.juku.app://callback` for OAuth

### Supabase
- URL + anon key in `lib/core/supabase_config.dart`
- Realtime: chat only. Dashboard stats: poll every 30–60s. NO Realtime for XP/level.
- RLS REQUIRED on every table — no exceptions

---

## Supabase Backend

- **URL:** `https://tipinjxdupfwntmkarkj.supabase.co`
- **Core tables:** profiles, lessons, follows, blocks, messages, topic_messages, xp_events, notifications, juice_wallets, juice_transactions, lesson_boosts, xp_multipliers, tips, learning_pods, world_objects, jukumon_cosmetics, user_cosmetics, builder_xp
- **Skill Mode tables (20 live):** skill_mode_modules, skill_mode_cards, skill_mode_sessions, skill_mode_progress, skill_mode_decks, skill_mode_deck_cards, skill_mode_deck_purchases, skill_mode_audio_files, skill_mode_community_translations, skill_mode_translation_votes, skill_mode_duo_battles, skill_mode_battle_moves, skill_mode_challenges, skill_mode_conjugation_tables, skill_mode_earnable_items, skill_mode_user_items, skill_mode_song_competitions, skill_mode_competition_entries, skill_mode_competition_votes, skill_mode_writing_attempts
- **RPCs:** spend_juice, award_xp, cast_lesson_vote, toggle_topic_message_vote, credit_tip
- **Auth:** Email/password + Google OAuth. Deep link: `pro.juku.app://callback`
- **Migrations:** `supabase/migrations/` — write SQL here, NEVER edit DB directly. Supabase CLI blocked by IPv6 — run via SQL Editor manually. List in HANDOVER.md with ⏳.

---

## XP & Progression

- Create lesson: +10 XP | Upvote received: +4 XP | Daily action: +5 XP | 3-combo: +5 | 5-combo: +10 | Chat upvoted: +3
- Levels 1–10: 100 XP/level | 11–30: 250 XP/level | 31+: 500 XP/level
- Ranks: Bronze (L1) → Silver (L10) → Gold (L25) → Diamond (L50) → Mythic (L100)

---

## Gamification Standards

- **XP curve:** variable ratio reward schedule — NOT linear, NOT fixed interval
- **Streaks:** grace period (1 day) + streak freeze mechanic required
- **Achievements:** MUST have icon path, title, description, and rarity enum (Common/Rare/Epic/Legendary)
- **Animations:** 300ms ease-out entry, 200ms ease-in exit, >500ms celebrations with particle effect
- **Level thresholds:** defined in constants file, unit tested — NO magic numbers inline
- **Sound:** no new audio triggers without human approval
- **Aesthetic:** premium and kinetic, not childish

---

## Slash Commands

- `/gamification-review` — checks XP, streaks, achievements, animations against spec
- `/sprint-handoff` — runs gates, updates SPRINT.md + HANDOVER.md, commits, notifies Dispatch
- `/bug-hunt` — systematic: analyze, tests, null safety, async errors, edge cases

---

## Payment Credentials (obtained 2026-04-10)

- **Stripe:** pk_live + sk_live obtained ✅ (see DECISIONS.md D-001)
- **GoCardless:** Juku SM-15 access token obtained ✅
- **Cloudflare R2:** juku-skill-mode token created 2026-04-09 ✅
- **Cashflow Dashboard:** https://dapper-chimera-40bd96.netlify.app (source: `~/Documents/Claude/Projects/The-Builder/juku-cashflow.html`)

---

## ⏳ Manual Tasks Still Needed

- ⏳ Run seed script: `dart scripts/seed_skill_mode.dart`
- ⏳ Add R2 credentials to `.env` (Cloudflare dashboard → R2 → API tokens)
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

- Dart analysis: zero issues
- No `print()` in production — `debugPrint()` only in debug blocks
- Const constructors everywhere possible
- Named parameters preferred
- Feature-based folder structure (not layer-based)
- One widget per file for non-trivial widgets
- All backend calls through repository or service layer — no direct Supabase calls from widgets

---

## Commit Rules

```bash
git add -A
git commit -m "feat(gamification): add streak freeze mechanic"
git push origin main
```

- Commit after each completed feature — not at end of day
- Breaking changes: `feat!: description`
- NEVER force-push to main

---

## Communication — Mobile First

Dhayan manages everything from iPhone. He is NEVER watching the Mac screen.

- Every task complete → Dispatch: `[JUKU] ✅ Task — one-line summary`
- Every blocker → Dispatch: `[JUKU] 🚫 Blocked — what you need`
- Every manual task → HANDOVER.md with ⏳ + ONE Dispatch message
- NEVER stop building because a manual task is outstanding
- NEVER use Cowork chat as the output channel — Dhayan won't see it on mobile

---

## Related Repos & Paths

- **Next.js web:** `~/Documents/Claude/Projects/Juku/` (Adonis80/Claude_Juku) — maintenance only
- **Supabase migrations:** `~/Documents/Claude/Projects/Juku-Flutter/supabase/migrations/`
- **Builder system:** `~/Documents/Claude/Projects/The-Builder/HANDOVER.md` + `BUILDER_SYSTEM.md`
- **HANDOVER.md:** read at session start, write Juku section at session end

---

## Session End Checklist

Before exiting, ALWAYS:
1. `flutter analyze --no-pub` — zero issues
2. `flutter test --no-pub` — zero failures
3. Update SPRINT.md with task progress
4. Write Juku section in HANDOVER.md
5. `git add -A && git commit -m "..." && git push origin main`
6. Dispatch: `[JUKU] ✅ Session complete — summary`
7. If intentional exit: `touch ~/Documents/Claude/Projects/Juku-Flutter/.claude/session_done`
