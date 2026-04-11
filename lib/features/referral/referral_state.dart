import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'referral_service.dart';

/// Current user's referral code.
final referralCodeProvider = FutureProvider<String>(
  (ref) => ReferralService.instance.getMyReferralCode(),
);

/// Current user's referral stats.
final referralStatsProvider = FutureProvider<ReferralStats?>(
  (ref) => ReferralService.instance.getMyStats(),
);

/// Current user's referred users.
final myReferralsProvider = FutureProvider<List<Referral>>(
  (ref) => ReferralService.instance.getMyReferrals(),
);

/// Top referrers leaderboard.
final referralLeaderboardProvider = FutureProvider<List<ReferralStats>>(
  (ref) => ReferralService.instance.getLeaderboard(),
);
