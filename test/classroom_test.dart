import 'package:flutter_test/flutter_test.dart';
import 'package:juku/features/classroom/classroom_service.dart';

void main() {
  group('Classroom', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'cls-1',
        'teacher_id': 'u-1',
        'name': 'German Year 9',
        'description': 'Beginners German',
        'language': 'german',
        'join_code': 'abc123',
        'max_students': 30,
        'plan': 'free',
        'active': true,
        'created_at': '2026-04-11T10:00:00Z',
      };
      final c = Classroom.fromJson(json, students: 15);
      expect(c.name, 'German Year 9');
      expect(c.language, 'german');
      expect(c.joinCode, 'abc123');
      expect(c.maxStudents, 30);
      expect(c.studentCount, 15);
      expect(c.active, true);
    });

    test('fromJson uses defaults', () {
      final json = {
        'id': 'cls-2',
        'teacher_id': 'u-1',
        'name': 'Test',
        'join_code': 'xyz',
        'created_at': '2026-04-11T10:00:00Z',
      };
      final c = Classroom.fromJson(json);
      expect(c.language, 'german');
      expect(c.maxStudents, 30);
      expect(c.plan, 'free');
      expect(c.studentCount, 0);
    });
  });

  group('ClassroomMember', () {
    test('fromJson with profile', () {
      final json = {
        'id': 'mem-1',
        'classroom_id': 'cls-1',
        'user_id': 'u-2',
        'role': 'student',
        'joined_at': '2026-04-11T12:00:00Z',
        'profiles': {'username': 'alice', 'display_name': 'Alice'},
      };
      final m = ClassroomMember.fromJson(json);
      expect(m.username, 'alice');
      expect(m.displayName, 'Alice');
      expect(m.role, 'student');
    });

    test('fromJson without profile', () {
      final json = {
        'id': 'mem-2',
        'classroom_id': 'cls-1',
        'user_id': 'u-3',
        'joined_at': '2026-04-11T12:00:00Z',
      };
      final m = ClassroomMember.fromJson(json);
      expect(m.username, isNull);
      expect(m.role, 'student');
    });
  });

  group('ClassroomContent', () {
    test('fromJson with due date', () {
      final json = {
        'id': 'cc-1',
        'classroom_id': 'cls-1',
        'module_id': 'mod-1',
        'module_title': 'German Greetings',
        'assigned_at': '2026-04-11T10:00:00Z',
        'due_date': '2026-04-18',
      };
      final c = ClassroomContent.fromJson(json);
      expect(c.moduleTitle, 'German Greetings');
      expect(c.dueDate, isNotNull);
      expect(c.dueDate!.day, 18);
    });

    test('fromJson without due date', () {
      final json = {
        'id': 'cc-2',
        'classroom_id': 'cls-1',
        'module_id': 'mod-2',
        'module_title': 'French Basics',
        'assigned_at': '2026-04-11T10:00:00Z',
      };
      final c = ClassroomContent.fromJson(json);
      expect(c.dueDate, isNull);
    });
  });
}
