import 'package:flutter_test/flutter_test.dart';
import 'package:juku/features/referral/referral_service.dart';

void main() {
  group('ReferralStats', () {
    test('fromJson parses all fields', () {
      final json = {
        'user_id': 'u-1',
        'username': 'alice',
        'display_name': 'Alice',
        'total_referrals': 12,
        'rewarded_count': 10,
      };
      final stats = ReferralStats.fromJson(json);
      expect(stats.userId, 'u-1');
      expect(stats.username, 'alice');
      expect(stats.totalReferrals, 12);
      expect(stats.rewardedCount, 10);
    });

    test('fromJson handles null counts', () {
      final json = {'user_id': 'u-2'};
      final stats = ReferralStats.fromJson(json);
      expect(stats.totalReferrals, 0);
      expect(stats.rewardedCount, 0);
    });
  });

  group('Referral', () {
    test('fromJson parses referral', () {
      final json = {
        'id': 'ref-1',
        'referrer_id': 'u-1',
        'referred_id': 'u-2',
        'referral_code': 'abc123',
        'juice_rewarded': true,
        'xp_rewarded': true,
        'created_at': '2026-04-11T10:00:00Z',
      };
      final ref = Referral.fromJson(json);
      expect(ref.referralCode, 'abc123');
      expect(ref.juiceRewarded, true);
      expect(ref.xpRewarded, true);
    });

    test('fromJson with referred profile', () {
      final json = {
        'id': 'ref-2',
        'referrer_id': 'u-1',
        'referred_id': 'u-3',
        'referral_code': 'def456',
        'juice_rewarded': false,
        'xp_rewarded': false,
        'created_at': '2026-04-11T12:00:00Z',
        'referred_profile': {'username': 'bob'},
      };
      final ref = Referral.fromJson(json);
      expect(ref.referredUsername, 'bob');
      expect(ref.juiceRewarded, false);
    });
  });

  group('ReferralService helpers', () {
    test('shareUrl generates correct URL', () {
      final url = ReferralService.shareUrl('abc123');
      expect(url, 'https://juku.pro/join?ref=abc123');
    });

    test('shareText includes code and URL', () {
      final text = ReferralService.shareText('abc123');
      expect(text, contains('abc123'));
      expect(text, contains('juku.pro/join'));
      expect(text, contains('50 Juice'));
      expect(text, contains('100 XP'));
    });
  });
}
