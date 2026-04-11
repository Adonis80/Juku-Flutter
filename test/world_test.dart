import 'package:flutter_test/flutter_test.dart';
import 'package:juku/features/world/world_service.dart';

void main() {
  group('WorldZone', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'z-1',
        'name': 'German Tavern',
        'language': 'german',
        'description': 'A rustic tavern',
        'ambient_theme': 'accordion',
        'max_capacity': 20,
      };
      final zone = WorldZone.fromJson(json, present: 5);
      expect(zone.id, 'z-1');
      expect(zone.name, 'German Tavern');
      expect(zone.language, 'german');
      expect(zone.ambientTheme, 'accordion');
      expect(zone.maxCapacity, 20);
      expect(zone.presentCount, 5);
    });

    test('fromJson uses defaults', () {
      final zone = WorldZone.fromJson({'id': 'z-2', 'name': 'General'});
      expect(zone.language, 'general');
      expect(zone.ambientTheme, 'default');
      expect(zone.maxCapacity, 20);
      expect(zone.presentCount, 0);
    });
  });

  group('PodMember', () {
    test('fromJson with profile data', () {
      final json = {
        'user_id': 'u-1',
        'position_x': 0.5,
        'position_y': 0.3,
        'joined_at': '2026-04-11T10:00:00Z',
        'profiles': {'username': 'alice', 'display_name': 'Alice'},
      };
      final m = PodMember.fromJson(json);
      expect(m.userId, 'u-1');
      expect(m.username, 'alice');
      expect(m.displayName, 'Alice');
      expect(m.posX, 0.5);
      expect(m.posY, 0.3);
    });

    test('fromJson without profile', () {
      final json = {'user_id': 'u-2', 'joined_at': '2026-04-11T10:00:00Z'};
      final m = PodMember.fromJson(json);
      expect(m.username, isNull);
      expect(m.posX, 0);
    });
  });

  group('WorldObject', () {
    test('fromJson parses catalog item', () {
      final json = {
        'id': 'obj-1',
        'name': 'Study Desk',
        'description': 'A wooden desk',
        'category': 'furniture',
        'juice_cost': 15,
        'seasonal': false,
      };
      final obj = WorldObject.fromJson(json);
      expect(obj.name, 'Study Desk');
      expect(obj.category, 'furniture');
      expect(obj.juiceCost, 15);
      expect(obj.seasonal, false);
    });

    test('seasonal object with availability window', () {
      final json = {
        'id': 'obj-2',
        'name': 'Christmas Tree',
        'category': 'seasonal',
        'juice_cost': 50,
        'seasonal': true,
        'available_until': '2026-12-31T23:59:59Z',
      };
      final obj = WorldObject.fromJson(json);
      expect(obj.seasonal, true);
      expect(obj.availableUntil, isNotNull);
    });
  });

  group('CardDrop', () {
    test('fromJson parses card drop', () {
      final json = {
        'id': 'drop-1',
        'zone_id': 'z-1',
        'dropped_by': 'u-1',
        'card_id': 'card-1',
        'card_title': 'German Greetings',
        'card_type': 'flash',
        'position_x': 0.3,
        'position_y': 0.7,
        'play_count': 5,
        'expires_at': '2026-04-12T10:00:00Z',
        'created_at': '2026-04-11T10:00:00Z',
        'profiles': {'username': 'alice'},
      };
      final drop = CardDrop.fromJson(json);
      expect(drop.cardTitle, 'German Greetings');
      expect(drop.playCount, 5);
      expect(drop.dropperName, 'alice');
      expect(drop.posX, 0.3);
    });

    test('isExpired returns true for past dates', () {
      final json = {
        'id': 'drop-2',
        'zone_id': 'z-1',
        'dropped_by': 'u-1',
        'card_id': 'card-2',
        'card_title': 'Old Drop',
        'expires_at': '2020-01-01T00:00:00Z',
        'created_at': '2019-12-31T00:00:00Z',
      };
      final drop = CardDrop.fromJson(json);
      expect(drop.isExpired, true);
    });

    test('isExpired returns false for future dates', () {
      final json = {
        'id': 'drop-3',
        'zone_id': 'z-1',
        'dropped_by': 'u-1',
        'card_id': 'card-3',
        'card_title': 'Future Drop',
        'expires_at': '2030-01-01T00:00:00Z',
        'created_at': '2026-04-11T00:00:00Z',
      };
      final drop = CardDrop.fromJson(json);
      expect(drop.isExpired, false);
    });
  });

  group('ObjectGift', () {
    test('fromJson parses gift', () {
      final json = {
        'id': 'gift-1',
        'object_id': 'obj-1',
        'from_user_id': 'u-1',
        'to_user_id': 'u-2',
        'message': 'Enjoy this desk!',
        'claimed': false,
        'created_at': '2026-04-11T10:00:00Z',
      };
      final gift = ObjectGift.fromJson(json);
      expect(gift.message, 'Enjoy this desk!');
      expect(gift.claimed, false);
    });

    test('fromJson with profile', () {
      final json = {
        'id': 'gift-2',
        'object_id': 'obj-2',
        'from_user_id': 'u-1',
        'to_user_id': 'u-2',
        'claimed': true,
        'created_at': '2026-04-11T10:00:00Z',
        'from_profile': {'username': 'bob'},
      };
      final gift = ObjectGift.fromJson(json);
      expect(gift.fromUsername, 'bob');
      expect(gift.claimed, true);
    });
  });
}
