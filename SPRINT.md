# SPRINT.md — Juku Flutter

**Last updated:** 2026-04-10
**Current status:** All engineering sprints complete

---

## Completed Sprints

| Sprint | What | Date |
|---|---|---|
| 0–9 | Core app, gamification, content, UI polish, mobile UX, dark mode | Pre-2026-04-09 |
| 10 | Profiles, OAuth, BYOK AI, Juice economy | Pre-2026-04-09 |
| 11 | Gamification v2, leaderboard tabs, 10 badges, Jukumon companion | Pre-2026-04-09 |
| 12 | Multi-Tenant / White-Label Foundation | Pre-2026-04-09 |
| 13 | Micro-Tipping ("Send Props") + Creator Earnings | Pre-2026-04-09 |
| 14 | Interactive Visuals & Knowledge Graph | Pre-2026-04-09 |
| 15 | Learning Circles (Groups of 5) | Pre-2026-04-09 |
| 16 | Meta Social Layer | Pre-2026-04-09 |
| 17 | WhatsApp Calling & Practice Sessions | Pre-2026-04-09 |
| 18 | Jukumon x Meta Horizon VR World | Pre-2026-04-09 |
| 19 | World Builder: Objects, Pods, Sponsorships, Cosmetics, Builder XP | Pre-2026-04-09 |
| 20 | Flutter Core Screens | Pre-2026-04-09 |
| 21 | Flutter: Notifications, bookmarks, topic feeds, settings, NFC invite | Pre-2026-04-09 |
| 22 | Flutter: Leaderboard, Juice wallet, World Builder, Circles | Pre-2026-04-09 |
| 23 | Juku Studio MVP | Pre-2026-04-09 |
| 24 | Multiplayer Quiz + Conditional Calculator | Pre-2026-04-09 |
| SM-0 | Skill Mode Foundation | 2026-04-09 |
| SM-1 | Tile Engine + Three-Press Interaction + Magnet Animation | 2026-04-09 |
| SM-2 | Shuffle Puzzle + Conjugation Dial + Audio Integration | 2026-04-09 |
| SM-3 | Gamification: HUD, XP Engine, Streaks, Badges | 2026-04-09 |
| SM-4 | Speak-to-Advance: Pronunciation Scoring | 2026-04-09 |
| SM-2.5 | Deck Builder + Marketplace | 2026-04-09 |
| SM-3.5 | Creator Economy + Competition | 2026-04-09 |
| SM-5 | Music Mode v0.4 | 2026-04-09 |
| SM-6 | Community Translations v0.5 | 2026-04-10 |
| SM-7 | Multi-Language v1.0 (German, French, Russian, Arabic, Mandarin) | 2026-04-10 |
| SM-8 | Duo Battle — real-time multiplayer race | 2026-04-10 |
| SM-9 | Challenge Mode — async 1v1 challenges | 2026-04-10 |
| SM-10 | Conjugation Table View | 2026-04-10 |
| SM-11 | Streak Freeze + XP Booster earnable items | 2026-04-10 |
| SM-12 | Writing Mode — stroke order tracing | 2026-04-10 |
| SM-13 | Song Translation Competitions | 2026-04-10 |
| SM-14 | App Polish — splash, onboarding, error boundary | 2026-04-10 |
| 23.5 | Gamified play overhauls, branding editor, image upload, cover art | 2026-04-10 |

---

## Current Sprint

### SM-15 — Payment v2: Hybrid Stripe + GoCardless ✅

**Goal:** Wire up real payment flows for Juice top-ups (Stripe card) and creator payouts (GoCardless direct debit). No Apple/Google IAP — all payments web or direct debit.

**Full spec:** DECISIONS.md D-001

**Acceptance criteria:**
- [x] Juice Wallet screen: payment method selector (Card via Stripe / Bank via GoCardless)
- [x] Stripe card top-up: user enters amount → Stripe PaymentSheet → Juice credited
- [x] GoCardless mandate setup: link from app → browser → GoCardless hosted page → back via deep link
- [x] `juice_ledger` table: weekly tip accumulations per user
- [x] `payment_methods` table: stored card (Stripe) or bank (GoCardless mandate)
- [x] `settlements` table: weekly settlement records (amount, method, status)
- [x] `settle-weekly` Edge Function: cron Sunday 23:00 UTC, calculates net balance, triggers charges/payouts
- [x] `gocardless-webhook` Edge Function: handles mandate confirmation, payment events
- [x] Flutter: Juice top-up flow with Stripe PaymentSheet integration
- [x] Flutter: GoCardless mandate setup flow (browser → deep link callback)
- [x] Flutter: Settlement history screen in Juice Wallet (3-tab wallet: Wallet / Payment / Settlements)
- [x] All new tables have RLS enabled
- [x] `flutter analyze` zero errors

**Credentials:** Stripe pk_live/sk_live ✅ — GoCardless token ✅ — add to Supabase secrets before deploying

**What was built:**
- Migration: `20260422000000_payment_v2.sql` — 3 tables (payment_methods, juice_ledger, settlements), RLS, credit_juice RPC, updated spend_juice RPC with ledger tracking
- Edge Functions: `create-payment-intent` (Stripe PaymentIntent + SetupIntent), `stripe-webhook`, `settle-weekly`, `gocardless-webhook`, `create-gocardless-redirect`
- Flutter: `payment_service.dart` (Stripe PaymentSheet, GoCardless mandate, CRUD for payment methods/settlements)
- Flutter: Juice Wallet rewritten with 3-tab layout (Wallet / Payment Methods / Settlements), fee comparison info card
- Packages added: `flutter_stripe ^12.6.0`, `url_launcher ^6.3.1`
- Stripe initialized in `main.dart` via `String.fromEnvironment('STRIPE_PK')`

---

## Backlog

- **23.5.6:** Sound packs (blocked — needs manual audio sourcing from freesound.org)

---

## Session Notes

This session (2026-04-10):
- Fixed Stop hook in `.claude/settings.json` — replaced `$HOME` with hardcoded paths (was rendering as `__TRACKED_VAR__`)
- Hook further refined: uses `⏳` marker instead of broad sprint pattern matching to detect pending work
- No code changes to the app itself
