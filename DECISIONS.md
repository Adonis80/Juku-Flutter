# DECISIONS.md — Juku Flutter

All significant technical and product decisions with reasoning. Check before making new decisions to avoid repeating past debates.

---

## D-004 — Multi-Platform Expansion: Meta Quest / VR (2026-04-11)

**Decision:** Defer full Meta Quest / VR support. No action needed now. Re-evaluate at 50k+ users.

**Findings:**
- Flutter Android APKs *can* sideload on Meta Quest via `adb install`, but: no Google Play Services (blocks Firebase-dependent features), no camera, targets Android 12L.
- 2D panel experiences on Quest work via Meta Spatial SDK — but that's native Android/Kotlin, not Flutter. A proper 2D panel app would require a parallel native build.
- Immersive VR (fully 3D, spatial UI) requires Unity or Unreal + Meta XR SDK. Separate codebase, separate team.
- **Meta Horizon Worlds** is not an integration target — as of Feb 2026 the VR version is sunsetting (June 2026), pivoting to mobile. No public API for embedding third-party apps.

**Verdict by tier:**
| Option | Effort | Value | Decision |
|---|---|---|---|
| Sideload Flutter APK on Quest (2D panel) | Low | Low (niche) | Skip for now |
| Native 2D panel via Meta Spatial SDK | High (separate codebase) | Medium | Defer to v2+ |
| Immersive VR experience (Unity/Unreal) | Very high | High (long-term) | Roadmap item 2027+ |
| Meta Horizon Worlds integration | N/A | None | Skip entirely |

**When to revisit:** When Quest becomes a mainstream language learning device (market signal: Duolingo Quest app). Not before.

---

## D-003 — Multi-Platform Expansion: Apple Watch / Apple TV / Vision Pro (2026-04-11)

**Decision:** Add visionOS support now (trivial). Defer Apple Watch to v2. Skip Apple TV.

**Findings:**

**Apple Vision Pro (visionOS):**
- Flutter apps run in visionOS "floating window" compatibility mode automatically — essentially iPad app in a spatial window.
- Enable: add `visionOS` to Xcode supported destinations, exclude Intel x86 slice. ~4–6 hours of testing.
- No spatial hand-tracking or RealityKit — it's a flat window floating in space. That's fine for Juku.
- Growing premium early-adopter audience. Differentiator: almost no language learning apps have a Vision Pro build.
- **Decision: DO IT NOW** — add to App Store submission. Near-zero effort.

**Apple Watch (watchOS):**
- No official Flutter support. Requires native Swift WatchKit companion app alongside the Flutter iOS app.
- Communication via `flutter_watch_os_connectivity` package + Pigeon code generators.
- Effort: ~20–30 hours for a native Swift watch extension.
- Best use case for Juku: streak notifications, daily XP summary, quick vocab flashcard glance.
- **Decision: v2 sprint** — high user value (habits + streaks) once the main app is in the App Store.

**Apple TV (tvOS):**
- No official Flutter tvOS support. Community fork exists (Flutter 3.24.1 max) — not production-ready.
- Language learning on a TV is a niche use case. Limited input method (remote only).
- **Decision: Skip entirely.** Not worth the maintenance burden.

**Sprint scope for visionOS (SP-VOS-1):**
1. Xcode: add visionOS destination to Runner target
2. Exclude x86_64 from build settings
3. Test all screens in visionOS Simulator — fix any layout issues (safe area, window chrome)
4. Update App Store metadata: add visionOS screenshots

---

## D-002 — Upgrade `record` package 5.2.1 → 6.2.0 to fix Xcode 26.4 build failure (2026-04-11)

**Decision:** Upgrade `record` from `^5.2.0` to `^6.2.0` in pubspec.yaml.

**Why:**
- `flutter build ios` failed with `Target kernel_snapshot_program failed` on Xcode 26.4 / iOS 26.3.
- Root cause: `record 5.2.1` pulled in `record_linux 0.7.2` which was incompatible with `record_platform_interface 1.5.0` — missing `startStream` method and changed `hasPermission` signature. Even though we build for iOS, Flutter's Dart compiler compiles all platform implementations during kernel snapshot.
- `record 6.2.0` resolves `record_linux 1.3.0` (compatible) and splits `record_darwin` into `record_ios 1.2.0` + `record_macos 1.2.1`.
- No breaking API changes between 5.x and 6.x for the APIs we use (`AudioRecorder`, `hasPermission`, `start`, `stop`, `getAmplitude`, `RecordConfig`).

**Affected files:** `pubspec.yaml` (1 line), `pubspec.lock` (auto-resolved).

**Alternatives considered:**
- `dependency_overrides` to pin `record_linux` — fragile, hides the real version gap
- Removing `record` entirely — needed for Skill Mode pronunciation recording (SM-4.2)

---

## D-001 — Payment Architecture: Hybrid Stripe + GoCardless (2026-04-10)

**Decision:** Use a hybrid payment model for the Juice economy.
- **Stripe** — card top-ups for casual users (fast, familiar UX)
- **GoCardless** — direct debit for power users and creator payouts (cheaper fees)
- **Weekly ledger settlement** — tips accumulate in Supabase all week, one charge/payout per user on Sunday night

**Why:**
- Per-tip card charging is uneconomic: a 50p tip via Stripe card costs ~60% in fees
- Batching to weekly settlement reduces card fees to one hit per user per week
- GoCardless direct debit: UK 0.5% + 20p (capped £4), US $0.30 flat ACH — far cheaper than Stripe's 2.9% + 30¢
- Hybrid covers both audiences: casual users prefer card, creators/power users will set up direct debit for lower fees

**Settlement flow:**
```
Mon–Sun: all Juice tips recorded in Supabase ledger (no real money moves)
Sunday 23:00 UTC: settlement job runs
  → net_balance < 0 (spent more than earned) → GoCardless pulls from bank / Stripe charges card
  → net_balance > 0 (earned more than spent) → GoCardless pays out to bank account
Monday 00:00: ledger resets
```

**Avoid:** Apple/Google in-app purchase for Juice top-ups (30% cut). All payments go through web (Stripe) or direct debit (GoCardless) outside the app stores.

**Alternatives considered:**
- Stripe only — simpler but 2.9% + 30¢ per tip is unworkable at small tip sizes
- PayPal — similar fees to Stripe, no direct debit advantage
- Per-transaction settlement — too expensive at micro-tip scale

---
