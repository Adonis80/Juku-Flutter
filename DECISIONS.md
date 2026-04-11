# DECISIONS.md — Juku Flutter

All significant technical and product decisions with reasoning. Check before making new decisions to avoid repeating past debates.

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
