import 'package:flutter/material.dart';

/// Displays Privacy Policy or Terms of Service in-app.
class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ),
    );
  }
}

const privacyPolicyText = '''
JUKU PRIVACY POLICY

Last updated: April 11, 2026

1. INTRODUCTION

Juku ("we", "us", "our") operates the Juku mobile application. This Privacy Policy explains how we collect, use, and protect your information.

2. INFORMATION WE COLLECT

Account Information: When you create an account, we collect your email address, display name, and optional profile photo URL.

Learning Data: We collect data about your learning sessions, including cards played, scores, streaks, XP earned, and time spent. This data is used to personalise your experience and track progress.

Content You Create: Lessons, cards, modules, translations, and other content you publish on Juku.

Payment Information: If you use Juice top-ups, payment processing is handled by Stripe and GoCardless. We do not store card numbers or bank details directly.

Usage Data: We collect anonymised usage statistics to improve the app, including screen views, feature usage, and crash reports.

3. HOW WE USE YOUR INFORMATION

- To provide and improve the Juku learning experience
- To calculate XP, levels, ranks, streaks, and leaderboard positions
- To enable social features (chat, challenges, live sessions, follows)
- To process Juice transactions and creator payouts
- To send notifications you have opted into
- To maintain security and prevent abuse

4. DATA SHARING

We do not sell your personal data. We share data only with:
- Supabase (database hosting and authentication)
- Stripe (card payment processing)
- GoCardless (direct debit processing)
- Cloudflare (content delivery and image storage)

5. DATA RETENTION

Your data is retained for as long as your account is active. You can request deletion of your account and all associated data by contacting us.

6. YOUR RIGHTS

You have the right to:
- Access your personal data
- Correct inaccurate data
- Delete your account and data
- Export your data
- Withdraw consent for optional processing

7. CHILDREN

Juku is suitable for users of all ages. We do not knowingly collect additional personal data from children under 13 beyond what is necessary for the service.

8. SECURITY

We use industry-standard encryption (TLS/SSL) for data in transit and at rest. Row-level security is enforced on all database tables.

9. CHANGES

We may update this policy periodically. Significant changes will be communicated via in-app notification.

10. CONTACT

For privacy questions: privacy@juku.pro
''';

const termsOfServiceText = '''
JUKU TERMS OF SERVICE

Last updated: April 11, 2026

1. ACCEPTANCE

By using Juku, you agree to these Terms of Service. If you do not agree, do not use the app.

2. ACCOUNTS

You must provide accurate information when creating an account. You are responsible for maintaining the security of your account credentials. One account per person.

3. CONTENT

User Content: You retain ownership of content you create on Juku (lessons, cards, modules, translations). By publishing content, you grant Juku a non-exclusive, worldwide licence to display and distribute it within the platform.

Prohibited Content: You may not publish content that is illegal, hateful, harassing, sexually explicit, or that infringes on intellectual property rights.

Moderation: Tenant administrators and Juku staff may moderate content within their communities. Content that violates these terms may be removed without notice.

4. JUICE ECONOMY

Juice is an in-app currency. Juice has no real-world monetary value and cannot be exchanged for cash except through the creator payout system.

Creator Payouts: Creators who earn Juice through marketplace sales and tips may be eligible for weekly settlements via Stripe or GoCardless, subject to minimum payout thresholds.

Refunds: Juice purchases are non-refundable except as required by law.

5. TENANTS

Tenant administrators are responsible for the content and conduct within their branded communities. Juku is not liable for content published within tenant namespaces.

6. FAIR USE

Do not use automated systems, bots, or scripts to interact with Juku. Do not attempt to manipulate XP, leaderboards, or the Juice economy. Violations may result in account suspension.

7. INTELLECTUAL PROPERTY

Juku, the Juku logo, Jukumon, and related marks are trademarks of Juku. The app's source code, design, and infrastructure are proprietary.

8. LIMITATION OF LIABILITY

Juku is provided "as is" without warranties. We are not liable for data loss, service interruptions, or indirect damages arising from use of the app.

9. TERMINATION

We may suspend or terminate accounts that violate these terms. You may delete your account at any time through Settings.

10. GOVERNING LAW

These terms are governed by the laws of England and Wales.

11. CHANGES

We may update these terms. Continued use after changes constitutes acceptance.

12. CONTACT

For questions: legal@juku.pro
''';
