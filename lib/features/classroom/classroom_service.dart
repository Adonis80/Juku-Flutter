import '../../core/supabase_config.dart';

class Classroom {
  final String id;
  final String teacherId;
  final String name;
  final String? description;
  final String language;
  final String joinCode;
  final int maxStudents;
  final String plan;
  final bool active;
  final DateTime createdAt;
  final int studentCount;

  const Classroom({
    required this.id,
    required this.teacherId,
    required this.name,
    this.description,
    required this.language,
    required this.joinCode,
    this.maxStudents = 30,
    this.plan = 'free',
    this.active = true,
    required this.createdAt,
    this.studentCount = 0,
  });

  factory Classroom.fromJson(Map<String, dynamic> json, {int students = 0}) =>
      Classroom(
        id: json['id'] as String,
        teacherId: json['teacher_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        language: json['language'] as String? ?? 'german',
        joinCode: json['join_code'] as String,
        maxStudents: json['max_students'] as int? ?? 30,
        plan: json['plan'] as String? ?? 'free',
        active: json['active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        studentCount: students,
      );
}

class ClassroomMember {
  final String id;
  final String classroomId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final String? username;
  final String? displayName;

  const ClassroomMember({
    required this.id,
    required this.classroomId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.username,
    this.displayName,
  });

  factory ClassroomMember.fromJson(Map<String, dynamic> json) =>
      ClassroomMember(
        id: json['id'] as String,
        classroomId: json['classroom_id'] as String,
        userId: json['user_id'] as String,
        role: json['role'] as String? ?? 'student',
        joinedAt: DateTime.parse(json['joined_at'] as String),
        username:
            (json['profiles'] as Map<String, dynamic>?)?['username'] as String?,
        displayName:
            (json['profiles'] as Map<String, dynamic>?)?['display_name']
                as String?,
      );
}

class ClassroomContent {
  final String id;
  final String classroomId;
  final String moduleId;
  final String moduleTitle;
  final DateTime assignedAt;
  final DateTime? dueDate;

  const ClassroomContent({
    required this.id,
    required this.classroomId,
    required this.moduleId,
    required this.moduleTitle,
    required this.assignedAt,
    this.dueDate,
  });

  factory ClassroomContent.fromJson(Map<String, dynamic> json) =>
      ClassroomContent(
        id: json['id'] as String,
        classroomId: json['classroom_id'] as String,
        moduleId: json['module_id'] as String,
        moduleTitle: json['module_title'] as String,
        assignedAt: DateTime.parse(json['assigned_at'] as String),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
      );
}

/// Service for classroom operations.
class ClassroomService {
  ClassroomService._();
  static final instance = ClassroomService._();

  final _sb = supabase;

  // --- Teacher Operations ---

  Future<List<Classroom>> getMyClassrooms() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _sb
        .from('classrooms')
        .select()
        .eq('teacher_id', uid)
        .order('created_at', ascending: false);

    // Get student counts
    final classIds = rows.map((r) => r['id'] as String).toList();
    final members = await _sb
        .from('classroom_members')
        .select('classroom_id')
        .inFilter('classroom_id', classIds);

    final countMap = <String, int>{};
    for (final m in members) {
      final cid = m['classroom_id'] as String;
      countMap[cid] = (countMap[cid] ?? 0) + 1;
    }

    return rows
        .map(
          (r) =>
              Classroom.fromJson(r, students: countMap[r['id'] as String] ?? 0),
        )
        .toList();
  }

  Future<Classroom> createClassroom({
    required String name,
    String? description,
    String language = 'german',
  }) async {
    final uid = _sb.auth.currentUser!.id;
    final row = await _sb
        .from('classrooms')
        .insert({
          'teacher_id': uid,
          'name': name,
          'description': description,
          'language': language,
        })
        .select()
        .single();
    return Classroom.fromJson(row);
  }

  Future<void> deleteClassroom(String classroomId) async {
    await _sb.from('classrooms').delete().eq('id', classroomId);
  }

  Future<List<ClassroomMember>> getStudents(String classroomId) async {
    final rows = await _sb
        .from('classroom_members')
        .select('*, profiles(username, display_name)')
        .eq('classroom_id', classroomId)
        .order('joined_at');
    return rows.map((r) => ClassroomMember.fromJson(r)).toList();
  }

  Future<void> removeStudent(String classroomId, String userId) async {
    await _sb
        .from('classroom_members')
        .delete()
        .eq('classroom_id', classroomId)
        .eq('user_id', userId);
  }

  // --- Content ---

  Future<void> assignContent({
    required String classroomId,
    required String moduleId,
    required String moduleTitle,
    DateTime? dueDate,
  }) async {
    await _sb.from('classroom_content').insert({
      'classroom_id': classroomId,
      'module_id': moduleId,
      'module_title': moduleTitle,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'assigned_by': _sb.auth.currentUser!.id,
    });
  }

  Future<List<ClassroomContent>> getAssignedContent(String classroomId) async {
    final rows = await _sb
        .from('classroom_content')
        .select()
        .eq('classroom_id', classroomId)
        .order('assigned_at', ascending: false);
    return rows.map((r) => ClassroomContent.fromJson(r)).toList();
  }

  // --- Student Operations ---

  Future<String> joinClassroom(String joinCode) async {
    final result = await _sb.rpc(
      'join_classroom',
      params: {'p_join_code': joinCode},
    );
    return result as String;
  }

  Future<List<Classroom>> getJoinedClassrooms() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    final memberships = await _sb
        .from('classroom_members')
        .select('classroom_id')
        .eq('user_id', uid);

    if (memberships.isEmpty) return [];

    final classIds = memberships
        .map((m) => m['classroom_id'] as String)
        .toList();

    final rows = await _sb
        .from('classrooms')
        .select()
        .inFilter('id', classIds)
        .order('name');

    return rows.map((r) => Classroom.fromJson(r)).toList();
  }
}
