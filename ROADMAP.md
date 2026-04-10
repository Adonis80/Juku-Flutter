# ROADMAP.md — Juku Flutter

**Last updated:** 2026-04-10
**Status:** SM-15 is current sprint. SM-16 through App Store launch all planned below.

---

## Vision

Juku is not a language learning app. It is a **live knowledge network** — the social layer that turns learning into a sport, a ritual, and a culture. The roadmap below takes the completed technical foundation (SM-0 through SM-14) and turns it into something people talk about, share, and return to every single day.

Every sprint below is designed around three constraints:
1. **Self-financing** — each feature either generates Juice revenue, attracts tenants, or builds creator supply
2. **Viral by default** — every feature has a sharing or competitive layer built in from day one
3. **World-class motion** — nothing ships without animation, sound, and haptics

---

## SM-15 — Payment v2: Stripe + GoCardless

**Theme:** The moment Juku stops being a demo and starts being a business

**Revenue impact:** Unlocks real Juice top-ups and creator payouts. Foundation for all monetisation after this sprint.

**Visual design:** Juice Wallet redesign — animated balance counter (like a slot machine when Juice is credited), payment method selector with a card flip animation between Stripe/GoCardless options, success state with a Juice burst particle effect (gold coins scattering from the top)

**Sound design:** Coin drop sound on Juice credit (satisfying weighted "thud" not a cheap ping), subtle cash-register on settlement confirmation, gentle chime on GoCardless mandate setup completion

**Social layer:** Creator earnings dashboard shows "this week's tips" as a live counter. Share earnings milestone to profile ("I just earned my first £10 on Juku").

**Acceptance criteria:**
- Juice Wallet screen: payment method selector (Card via Stripe / Bank via GoCardless)
- Stripe PaymentSheet integration: user picks amount → Stripe handles card UI → Juice credited on success
- GoCardless mandate flow: button → in-app browser → GoCardless hosted page → deep link callback → mandate stored
- `juice_ledger` table: weekly tip accumulations per user (with RLS)
- `payment_methods` table: stored card token (Stripe) or mandate ID (GoCardless), per user
- `settlements` table: records per user per week (amount, status: pending/processing/complete/failed)
- `settle-weekly` Supabase Edge Function: cron Sunday 23:00 UTC, net balance per user, triggers charge (negative) or payout (positive)
- `gocardless-webhook` Edge Function: handles mandate_created, payment_paid_out, payment_failed events
- Settlement history tab in Juice Wallet: list of past weeks, status badges, amount in/out
- All new Supabase tables have RLS enabled
- `flutter analyze` zero issues

**New tables:** `juice_ledger`, `payment_methods`, `settlements`
**New Edge Functions:** `settle-weekly`, `gocardless-webhook`
**Effort:** L

---

## SM-16 — Juku Live

**Theme:** Learning becomes a spectator sport

**Revenue impact:** Hosts earn Juice gifts in real time. Live sessions drive top-up urgency ("I want to send a gift NOW"). Premium hosts can charge Juice entry fee per session.

**Visual design:**
- Live screen: dark broadcast aesthetic, host card displayed centre-stage in a pulsing border (colour cycles based on session energy — slow purple at start, electric yellow when gifts fly)
- Viewer count badge top-right with a heartbeat animation
- Juku Live logo: animated TV-static intro (0.3 seconds) when joining
- Gift animations: when a viewer sends Juice, a full-screen animation fires — the gift type determines the visual (🌊 Wave = ripple across screen, 🔥 Fire = particles shoot upward, 👑 Crown = golden crown drops from top and lands on host)
- Leaderboard ticker at bottom: scrolling "top gifters this session" names
- Session replay: saved as a card in the host's profile, thumbnail = frame from peak gift moment

**Sound design:**
- "You're live" jingle: short ascending fanfare (3 notes, builds excitement)
- Gift sounds: each gift type has a distinct layered sound — Wave is a water-rush, Fire is a crackling burst, Crown is a royal fanfare hit with reverb tail
- Viewer join notification: soft "whoosh" directionally panned, one per join (throttled after 10+ viewers)
- Leaderboard update: subtle "ding" when rank changes

**Social layer:**
- Hosts get a shareable "I'm going live" card (auto-generated, shows time and topic)
- Post-session summary card: "X viewers, Y Juice earned, top gifter: @username" — shareable to any app
- Followers get a push notification when someone they follow goes live

**Acceptance criteria:**
- Host can start a live session from their profile
- Supabase Realtime channel per session — all viewers connected
- Current card displayed in sync (host controls card progression, viewers see it simultaneously)
- Juice gifting: viewer selects gift tier (Wave=1J, Fire=5J, Crown=20J) → Juice debited → host credited → on-screen animation fires for all viewers
- Viewer count synced via presence channel
- Live leaderboard updates in real time (top 3 gifters by amount)
- Session ends: host taps End → replay saved → summary card shown
- Replay viewable on host profile
- Push notification to followers on session start
- `flutter analyze` zero issues

**New tables:** `live_sessions`, `live_gifts`
**Effort:** XL

---

## SM-17 — Juku Challenges (Viral Loop)

**Theme:** Everyone plays the same card today — then argues about it forever

**Revenue impact:** Daily challenge drives daily active users. Streak anxiety = Juice Freeze purchases. Streak milestones = XP booster purchases. Top-leaderboard ambition = potential Juice spend on boosts.

**Visual design:**
- Challenge reveal: each day at 00:00 UTC, the day's card "tears open" like a sealed envelope — foil effect, then the card slides in from behind
- Result share card: beautiful animated card (like Wordle share but kinetic) — shows your score, rank percentile, streak, and a colour-coded emoji grid of your answer sequence. Animates on creation (cards flip in one by one)
- Global leaderboard: 3D podium for top 3 (same style as cashflow dashboard), scrollable list below for #4–100, "your rank" sticky at bottom
- Streak counter: fire emoji with a number, animates when streak increments (bounces + glow)

**Sound design:**
- Challenge reveal: envelope tear sound + a single dramatic piano note
- Correct answer during challenge: ascending tone (same as Skill Mode but with a "competition" reverb)
- Wrong answer: low thud — no second chance, challenge is unforgiving
- Share card generated: satisfying "card snap" sound (like a photo being taken)
- Streak milestone (7, 30, 100 days): escalating fanfare — each milestone is louder and longer

**Social layer:**
- Share button on result screen generates animated card — works as a video (GIF) or static image
- Card includes: "Day X — [Language] Challenge", score, streak, and a subtle Juku watermark
- Challenge hashtag system: #JukuChallenge[DayNumber] auto-added to share text
- "Beat my score" direct challenge link (ties into SM-9 Challenge Mode)
- Weekly recap: Monday push notification showing last week's challenge stats + streak

**Acceptance criteria:**
- One challenge card pushed to all users at 00:00 UTC daily (Supabase scheduled function)
- Challenge card is the same for all users in same language pair
- Users have one attempt only — no retries
- Score calculated: time + accuracy combined formula
- Global leaderboard resets at 00:00 UTC (archived to weekly_leaderboard table)
- Personal streak: increments on consecutive daily attempts, breaks on miss
- Share card generated client-side (Flutter canvas → image → share_plus)
- Result card includes: score, rank percentile, streak count, answer colour grid
- Streak freeze item works for challenge too (SM-11 integration)
- Push notification at 08:00 local time: "Today's [Language] challenge is ready"
- `flutter analyze` zero issues

**New tables:** `daily_challenges`, `challenge_attempts`, `weekly_leaderboards`
**Effort:** L

---

## SM-18 — Jukumon Evolution v2

**Theme:** Your Jukumon is a mirror of who you are as a learner

**Revenue impact:** Rare Jukumon variants are cosmetic prestige items — limited seasonal drops sold for Juice. Mythic-rank Jukumon evolutions drive long-term retention (players grind for months to reach Mythic for the cinematic).

**Visual design:**
- Evolution system: Jukumon has 4 evolution branches based on dominant skill
  - Pronunciation branch: sleek, vocal-cord motif, sound-wave wings, blue/silver palette
  - Vocabulary branch: word-cloud body, ink-splash attack animation, purple/gold palette
  - Grammar branch: rigid geometric form, formula patterns on skin, green/white palette
  - Listening branch: large ear-like sensory organs, sonar pulse idle animation, teal/orange palette
- Evolution animation: full-screen cinematic triggered on evolution milestone. White light engulfs Jukumon → silhouette dissolves → new form assembles particle by particle → final reveal with camera flash effect. Total duration: 4 seconds. Unskippable.
- Jukumon on profile: displayed as a 3D-rotating card on public profile (Flutter CustomPainter with rotation gesture)
- Rare variants: holographic shimmer effect using Flutter's ShaderMask with an animated gradient
- Mythic-rank Jukumon: animated aura effect (rainbow chromatic aberration, 60fps custom painter)

**Sound design:**
- Evolution cinematic: custom composed 4-second audio piece — builds from silence → orchestral swell → reveal chord. Not a sound effect, a genuine musical moment.
- Rare variant unlock: crystalline shimmer sound (12 partials, bell-like, decays over 3 seconds)
- Jukumon attack/idle animations: soft ambient sounds tied to evolution type (Pronunciation → breath-like whoosh, Vocabulary → paper rustle, Grammar → mechanical click, Listening → sonar ping)
- Mythic aura: low constant harmonic hum (barely audible, creates a "presence")

**Social layer:**
- Jukumon shown on public profile — visitors can tap to see evolution branch and stats
- "My Jukumon evolved!" share card: video of the evolution cinematic (screen-recorded client-side or pre-rendered) + stats card
- Rare variants have a discovery leaderboard: "First 10 users to unlock Blaze Variant"
- Seasonal limited variants tied to real-world events (Chinese New Year → Dragon variant, Ramadan → Crescent variant, etc.)

**Acceptance criteria:**
- Dominant skill calculated from last 30 days of session data
- Evolution milestone: triggered at levels 5, 15, 30, 50, 100
- Each evolution milestone unlocks the next visual form
- Full-screen cinematic plays on evolution — Flutter AnimationController, Lottie, or CustomPainter
- Mythic rank (L100) unlocks final evolution with unique aura
- Public profile shows Jukumon with evolution branch label
- Rare variants purchasable from a "Variants" tab in Jukumon screen (Juice payment)
- Seasonal variants available for 30 days then retired
- `flutter analyze` zero issues

**New tables:** `jukumon_evolutions`, `jukumon_variants`, `seasonal_variants`
**Effort:** L

---

## SM-19 — Juku Studio Pro

**Theme:** If you can describe it, you can build it

**Revenue impact:** Creators pay Juice for AI generation credits, premium card types, and Studio Pro subscription (monthly Juice cost). Marketplace take-rate on sold decks. Tenant Studios (white-label Studio instances) are a B2B revenue line.

**Visual design:**
- Studio canvas: dark workspace aesthetic (like Figma dark mode). Card preview on right, controls on left.
- Drag-and-drop card type selector: cards slide in from a deck at the bottom — drag one up to add to your module
- AI generation panel: typing prompt → skeleton loader → content appears with a typewriter effect, then fades to final style
- Cover art generator: square canvas with brush-stroke generation animation (like DALL-E but shows intermediate steps)
- Audio recording: waveform visualiser during recording (real-time FFT via flutter_sound), pulse animation on peak
- Preview mode: module plays back exactly as a student would see it — full Skill Mode experience
- Publish: confetti burst + "Module is live" card with share link

**Sound design:**
- Drag-and-drop: satisfying "snap" when card type placed
- AI generation: subtle "thinking" drone (like a computer processing, 3–5 seconds), then a pleasant "complete" chime
- Audio recording start/stop: classic tape-recorder click
- Cover art generation: brush-stroke swoosh sounds playing while image generates
- Publish: multi-layered celebration — confetti pop, fanfare, then a single clear bell

**Social layer:**
- All modules published to public marketplace by default (can be set private for tenants)
- Creator profile shows "modules published" count and total plays
- "Studio Pro" badge on creator profile
- Module sharing: unique link (juku.pro/m/[slug]) embeds a playable preview card
- Creator revenue dashboard: real-time Juice earnings from marketplace sales and tips

**Acceptance criteria:**
- Card type library: minimum 8 types (text flash, audio card, gender tile, conjugation dial, shuffle puzzle, image match, fill-the-blank, multiple choice)
- AI generation: BYOLLM (user's own API key) for content suggestions
- Audio recording: record, playback, trim, re-record per card
- Cover art: AI generation via BYOLLM image model OR manual image upload (Cloudflare R2)
- Preview mode: full Skill Mode playback inside Studio
- Publish to marketplace: module appears in Explore within 60 seconds
- Revenue dashboard: shows Juice earned this week/month/all-time, per-module breakdown
- Tenant Studio mode: white-label Studio with tenant branding, private publishing to tenant namespace
- `flutter analyze` zero issues

**New tables:** `studio_sessions`, `studio_ai_credits`
**Effort:** XL

---

## SM-20 — White-Label Tenant Dashboard

**Theme:** Any community can launch their own Juku in 10 minutes

**Revenue impact:** Tenants pay monthly subscription (£99–£499/month depending on user count). This is the primary B2B revenue line. Target: 5 tenants at £199/month = £995 MRR from one sprint.

**Visual design:**
- Self-serve onboarding: 5-step wizard with progress bar, each step has a satisfying completion animation (checkmark draws itself, then pulses green)
- Branding customisation: live preview panel — drag your logo → see it appear on a phone mockup in real time. Colour picker with HSL sliders, live preview updates at 60fps.
- Analytics dashboard: 3D bar charts (same visual language as cashflow dashboard) showing DAU, content plays, Juice circulation, new users. All animated on load with spring physics.
- User management: list view with sort/filter, each user row has a subtle hover state (slide-in action buttons)
- Content moderation queue: swipe-left/right gesture (like Tinder) for approve/reject — satisfying haptic on each swipe

**Sound design:**
- Onboarding step complete: ascending 3-note sequence (C → E → G), clean and professional
- Content approved: gentle positive chime
- Content rejected: low thud (not harsh, just clear)
- Analytics dashboard load: data "assembles" with a subtle sweeping sound as bars rise
- Publish branding: camera shutter + "live" notification sound

**Social layer:**
- Tenant admin gets a "Your community is live on Juku" shareable card with their branding
- Tenant leaderboard: top tenants by engagement shown in a Juku-internal stats dashboard (bragging rights)
- Tenant referral: each tenant gets a referral code — bring another tenant, get one free month

**Acceptance criteria:**
- Self-serve signup: email → plan selection → branding upload → domain configuration → launch
- Custom branding: logo, primary colour, secondary colour, custom welcome message
- Content namespace: tenant's content is siloed — users in tenant only see tenant content by default
- User management: invite users, revoke access, view join date + activity level
- Moderation queue: approve/reject submitted cards with reason
- Analytics: DAU chart (30 days), content plays (by module), Juice circulation (in/out), new signups
- Billing portal: shows current plan, usage, next invoice date
- Custom domain support: tenant can CNAME their subdomain (e.g. learn.brandname.com) to Juku
- `flutter analyze` zero issues (Flutter admin panels use webview or dedicated Flutter screens)

**New tables:** `tenant_admins`, `tenant_analytics_snapshots`, `tenant_invites`
**Effort:** XL

---

## SM-21 — Juku World v2: Social Spaces

**Theme:** Learning is a place you go, not just a thing you do

**Revenue impact:** World objects are purchasable cosmetics (Juice). Limited edition seasonal objects (pumpkin pod at Halloween, igloo at Christmas) drive urgency and FOMO buying. Sponsorship model: brands can buy permanent world objects (language school logo on a building in the World).

**Visual design:**
- Pod entry: when two users are "in" the same pod, their Jukumon avatars appear face-to-face in a shared room. The room's aesthetic matches the pod's language (German pod → rustic Bavarian tavern, Arabic pod → ornate tiled courtyard, Mandarin pod → bamboo garden)
- Spatial audio: proximity-based volume — move your avatar toward another and their voice gets louder (Flutter + WebRTC or Supabase Realtime voice)
- Card drops: drag a card from your deck into the world — it floats as a glowing orb for 24 hours. Other users can tap to play it.
- Limited-edition objects: animated when placed — a Christmas tree drops snow particles, a lantern sways, a koi pond has animated fish
- Seasonal events: at New Year, confetti fills the World for all users simultaneously (Supabase Realtime broadcast)

**Sound design:**
- Pod ambient sound: each language pod has a matching ambient track (German: soft accordion, Arabic: oud, Mandarin: guqin, Russian: balalaika) — plays at 10% volume as background
- User enters pod: gentle portal "whoosh"
- Card drop: magical floating sound (crystalline shimmer)
- Seasonal event: event-specific audio (NYE: countdown + firework burst, Halloween: creaky door + ambient spooky)
- Proximity voice: custom audio processing to add "room" reverb based on your virtual position

**Social layer:**
- World is visible on profiles: "Dhayan is currently in the German Pod"
- Card drops are attributed: "Dropped by @username, 12h ago, played 47 times"
- Seasonal events are shared moments — push notification fires to all users simultaneously: "🎇 Happy New Year from Juku World"
- World object gifting: send a world object to a friend as a gift (Juice purchase, arrives with animation)

**Acceptance criteria:**
- Pod presence: tap "Enter Pod" → your avatar appears in the shared space → other present users' avatars visible
- Spatial audio: volume adjusts based on avatar proximity (WebRTC or Supabase Realtime voice channels)
- Card drop: drag card from deck onto world → orb appears → 24h expiry → other users can tap to play
- Limited-edition objects: purchasable during their seasonal window, placed in your World space
- Seasonal events: coordinated broadcast to all users via Supabase Realtime with visual + audio
- Object gifting: select object from shop → gift to user → recipient gets notification + animation
- `flutter analyze` zero issues

**New tables:** `world_pod_presence`, `world_card_drops`, `world_object_gifts`
**Effort:** XL

---

## SM-22 — App Store Launch Sprint

**Theme:** The world finds out Juku exists

**Revenue impact:** App Store listing = organic discovery. TestFlight beta = press + early adopter community. Launch day = first wave of paying users.

**Visual design:**
- App icon: final version by a designer. Direction: bold purple gradient, abstract "J" that reads as a book, a card, and a speech bubble simultaneously. Not a mascot, not a letter — an icon that looks premium at 60x60px and striking at 1024x1024px.
- App Store screenshots (6.9" iPhone): 6 screenshots, each tells one story:
  1. "Learn any language, one card at a time" — Skill Mode tile engine in action
  2. "Compete in real-time" — Duo Battle split-screen
  3. "Earn while you teach" — Creator earnings dashboard
  4. "Your Jukumon, your identity" — Jukumon evolution showcase
  5. "Go live and get paid" — Juku Live screenshot
  6. "The world's knowledge network" — World Builder overview
- Preview video: 30-second App Store preview. Opening shot: Jukumon evolving (cinematic). Cut to: Duo Battle at 2x speed. Cut to: creator publishing a deck. Cut to: Live session with gifts flying. End card: "Juku — Learn. Create. Earn."

**Sound design:** App Store preview video has a custom-composed 30-second track — starts minimal (single piano), builds through the product demo, peaks at Live session with full arrangement, resolves at end card.

**Social layer:**
- TestFlight beta: 200-person closed beta. Apply via juku.pro. Creates waitlist community.
- Launch day: coordinated Product Hunt launch. "Juku — the language learning network where creators get paid"
- Reddit launch posts to r/languagelearning, r/duolingo, r/learnspanish (and equivalents for target languages)
- Early user milestone: first 100 downloads → push notification to all users: "100 learners joined Juku this week" (community building)

**Acceptance criteria:**
- App icon: final design, all sizes generated (20px → 1024px)
- App Store screenshots: all 6 generated at correct sizes for 6.9" and 6.1" iPhone
- App Store preview video: 30-second MP4, H.264, correct App Store specs
- App Store description: 4000-character description written (title, subtitle, description, keywords, promotional text)
- Privacy Policy: hosted at juku.pro/privacy
- Terms of Service: hosted at juku.pro/terms
- TestFlight build: submitted and approved
- Submission checklist: all App Store Connect fields filled, content rating completed, export compliance answered
- No IAP in this build — payments are web-only (no 30% cut to Apple)
- `flutter analyze` zero issues, `flutter build ios` produces clean archive

**Effort:** L (content-heavy, not code-heavy)

---

## Post-Launch Growth Sprints

### GL-1 — Referral Engine
**Theme:** Every user is a sales channel

Give each user a unique referral link. Referred user joins → both get 50 Juice. Referred user completes first deck → both get 100 XP. Referral leaderboard (top referrers get Mythic cosmetic). Build a shareable "I've taught X people German on Juku" milestone card.

**Effort:** M

---

### GL-2 — Juku for Schools (B2B Pilot)
**Theme:** One email from a teacher = 30 new users

Self-serve classroom mode: teacher creates a class, invites students via code. Teacher dashboard shows student progress, streaks, lesson completion. Students see a class leaderboard. Content is teacher-curated (from marketplace). Free tier for teachers (up to 30 students), paid for larger classes. Target: 3 pilot schools in first 6 months.

**Effort:** L

---

### GL-3 — AI Conversation Partner
**Theme:** Practice talking, not just reading

Voice conversation screen: user speaks → transcribed by Whisper (via Edge Function) → AI responds as a native speaker → AI voice synthesised by ElevenLabs → playback. Score conversation at end: fluency, vocabulary, grammar. XP awarded. Unlock at Level 10. Uses user's own ElevenLabs key (BYOK). Practice sessions bookable with specific scenarios (airport, restaurant, job interview).

**Effort:** XL

---

## App #2 — Strategic Brief

**Trigger:** When Juku hits £5,000 MRR (any combination of Juice revenue + tenant subscriptions)

**Direction:** Habit tracker with social accountability. Working title: **Loop**.

**Why:** Juku users frequently ask for help building daily practice habits that extend beyond language learning — meditation, journaling, fitness, reading. The habit tracker market is proven but missing the social and gamification layer.

**Shared infrastructure:**
- Same Supabase instance — shared auth (Juku account = Loop account)
- Juku XP carries over (completing Loop habits earns Juku XP)
- Jukumon appears in Loop as your accountability companion
- Same Juice economy — earn Juice in Loop, spend in Juku

**Core differentiator:** Every habit has a public accountability layer. Miss a habit → your followers can see it. Complete a habit → share the streak. Challenge a friend to a 30-day habit race. Social shame + social pride = the most powerful retention mechanic that habit apps ignore.

**Builder system:** Use The Builder system to scaffold Loop exactly as Juku was scaffolded. Create Loop Claude Project. Fill PRODUCT.md, ARCHITECTURE.md, SPRINT.md, DECISIONS.md. Push to new GitHub repo. Start Claude Code session.

**Estimated setup:** 1 Builder Cowork session to plan, 2–3 autonomous overnight sessions to scaffold.

---

## Revenue Milestones

| MRR | What it unlocks |
|---|---|
| £500 | Apple Developer account ($99/yr) — TestFlight + App Store |
| £1,000 | First paid assistant (designer for app icon + screenshots) |
| £2,500 | First white-label tenant at £499/month plan |
| £5,000 | App #2 (Loop) — start The Builder session |
| £10,000 | Android version — Flutter build is cross-platform, just needs Play Store setup |
| £25,000 | Hire first full-time engineer via The Builder system (pair-program with Claude Code) |
| £50,000 | Series A exploration — Builder Cowork session to evaluate |

---

## Technical Principles (Applies to All Sprints)

**Never-before-seen gamification rules:**
- Every mechanic should have a "first time" moment that makes users say "woah"
- Animations must be spring-physics-based — no linear eases
- Sound is mandatory, not optional — every interaction has a sonic layer
- Social proof is always live — show what others are doing right now
- Scarcity and time pressure are features — limited-edition items, daily resets, countdowns

**Code quality gates (every sprint):**
- `flutter analyze` zero issues before commit
- No `print()` in production code
- Const constructors everywhere
- All new Supabase tables: RLS enabled, foreign keys reference `profiles.id`
- All new migrations in `supabase/migrations/` with timestamp prefix

**The Builder principles:**
- Never block on Dhayan for technical decisions
- Log every architectural decision in DECISIONS.md
- Notify via Dispatch after every completed task
- Exit at 60% context, restart fresh with HANDOVER.md
