import '../../core/supabase_config.dart';

class ReferralStats {
  final String userId;
  final String? username;
  final String? displayName;
  final int totalReferrals;
  final int rewardedCount;

  const ReferralStats({
    required this.userId,
    this.username,
    this.displayName,
    required this.totalReferrals,
    required this.rewardedCount,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
    userId: json['user_id'] as String,
    username: json['username'] as String?,
    displayName: json['display_name'] as String?,
    totalReferrals: json['total_referrals'] as int? ?? 0,
    rewardedCount: json['rewarded_count'] as int? ?? 0,
  );
}

class Referral {
  final String id;
  final String referrerId;
  final String referredId;
  final String referralCode;
  final bool juiceRewarded;
  final bool xpRewarded;
  final DateTime createdAt;
  final String? referredUsername;

  const Referral({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.referralCode,
    this.juiceRewarded = false,
    this.xpRewarded = false,
    required this.createdAt,
    this.referredUsername,
  });

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
    id: json['id'] as String,
    referrerId: json['referrer_id'] as String,
    referredId: json['referred_id'] as String,
    referralCode: json['referral_code'] as String,
    juiceRewarded: json['juice_rewarded'] as bool? ?? false,
    xpRewarded: json['xp_rewarded'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    referredUsername:
        (json['referred_profile'] as Map<String, dynamic>?)?['username']
            as String?,
  );
}

/// Service for referral engine operations.
class ReferralService {
  ReferralService._();
  static final instance = ReferralService._();

  final _sb = supabase;

  /// Get or create the current user's referral code.
  Future<String> getMyReferralCode() async {
    final result = await _sb.rpc('ensure_referral_code');
    return result as String;
  }

  /// Claim a referral code (called during signup flow).
  Future<void> claimReferral(String code) async {
    await _sb.rpc('claim_referral', params: {'p_referral_code': code});
  }

  /// Get the current user's referral stats.
  Future<ReferralStats?> getMyStats() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;

    final rows = await _sb
        .from('referral_leaderboard')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (rows == null) return null;
    return ReferralStats.fromJson(rows);
  }

  /// Get the list of users the current user has referred.
  Future<List<Referral>> getMyReferrals() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _sb
        .from('referrals')
        .select()
        .eq('referrer_id', uid)
        .order('created_at', ascending: false);
    return rows.map((r) => Referral.fromJson(r)).toList();
  }

  /// Get the referral leaderboard (top 50).
  Future<List<ReferralStats>> getLeaderboard() async {
    final rows = await _sb.from('referral_leaderboard').select().limit(50);
    return rows.map((r) => ReferralStats.fromJson(r)).toList();
  }

  /// Generate the share URL for a referral code.
  static String shareUrl(String code) => 'https://juku.pro/join?ref=$code';

  /// Generate share text for referral.
  static String shareText(String code) =>
      'Join me on Juku — the gamified language network! Use my code $code or sign up at ${shareUrl(code)} and we both get 50 Juice + 100 XP!';
}
