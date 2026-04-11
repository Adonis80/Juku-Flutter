# App Store Submission Checklist — Juku

## Pre-Submission (Code Complete)

- [x] `flutter analyze --no-pub` — zero issues
- [x] `flutter test --no-pub` — all tests pass (23 tests)
- [x] Privacy Policy — in-app at `/privacy`, to host at juku.pro/privacy
- [x] Terms of Service — in-app at `/terms`, to host at juku.pro/terms
- [x] App Store metadata written — `lib/core/app_store_metadata.dart`
- [x] Info.plist — microphone, camera, photo library descriptions set
- [x] Info.plist — `ITSAppUsesNonExemptEncryption` = NO (no custom encryption)
- [x] Deep link scheme: `pro.juku.app://callback` configured
- [x] No IAP — all payments web-only (Stripe/GoCardless)

## Manual Steps (Dhayan)

### Apple Developer Account
- [ ] Pay Apple Developer fee ($99/yr) — required for TestFlight + App Store
- [ ] Create App ID in Apple Developer portal: `pro.juku.app`
- [ ] Create provisioning profile (distribution)

### Xcode Signing
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Set Team = Apple Developer account (paid)
- [ ] Set Bundle ID = `pro.juku.app`
- [ ] Signing: Automatic

### App Store Connect
- [ ] Create new app in App Store Connect
- [ ] Primary category: Education
- [ ] Secondary category: Social Networking
- [ ] Age rating: 4+ (no objectionable content)
- [ ] Content rights: owns or has licence for all content
- [ ] Export compliance: uses HTTPS only (exempt from encryption regs)

### App Store Listing
- [ ] Title: "Juku — Learn, Create, Earn"
- [ ] Subtitle: "The gamified language network"
- [ ] Description: paste from `app_store_metadata.dart`
- [ ] Keywords: see `app_store_metadata.dart`
- [ ] Promotional text: see `app_store_metadata.dart`
- [ ] Support URL: https://juku.pro/support
- [ ] Privacy URL: https://juku.pro/privacy

### App Icon (Designer Task)
- [ ] Design app icon: bold purple gradient, abstract "J"
- [ ] Generate all sizes: 20px through 1024px
- [ ] Replace `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Screenshots (6.9" iPhone)
- [ ] Screenshot 1: "Learn any language, one card at a time" — Skill Mode
- [ ] Screenshot 2: "Compete in real-time" — Duo Battle
- [ ] Screenshot 3: "Earn while you teach" — Revenue dashboard
- [ ] Screenshot 4: "Your Jukumon, your identity" — Evolution
- [ ] Screenshot 5: "Go live and get paid" — Juku Live
- [ ] Screenshot 6: "The world's knowledge network" — World Builder
- [ ] Also generate 6.1" iPhone variants

### Preview Video
- [ ] 30-second video: Jukumon evolving → Duo Battle → Studio → Live → end card
- [ ] Format: H.264, 30fps, correct App Store dimensions
- [ ] Custom 30s audio track

### Build & Submit
- [ ] Run: `flutter build ios --release --dart-define=STRIPE_PK=pk_live_xxx`
- [ ] Archive in Xcode: Product → Archive
- [ ] Upload to App Store Connect via Xcode Organizer
- [ ] Submit for TestFlight review
- [ ] Once approved: invite 200 beta testers

### Post-Submission
- [ ] Host Privacy Policy at juku.pro/privacy
- [ ] Host Terms of Service at juku.pro/terms
- [ ] Create juku.pro/support page
- [ ] Reddit launch posts: r/languagelearning, r/duolingo, r/learnspanish
- [ ] Product Hunt listing
