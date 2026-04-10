# DECISIONS.md — Juku Flutter

All significant technical and product decisions with reasoning. Check before making new decisions to avoid repeating past debates.

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
