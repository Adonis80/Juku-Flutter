import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'classroom_service.dart';

/// Teacher's classrooms.
final myClassroomsProvider = FutureProvider<List<Classroom>>(
  (ref) => ClassroomService.instance.getMyClassrooms(),
);

/// Student's joined classrooms.
final joinedClassroomsProvider = FutureProvider<List<Classroom>>(
  (ref) => ClassroomService.instance.getJoinedClassrooms(),
);

/// Students in a specific classroom.
final classroomStudentsProvider =
    FutureProvider.family<List<ClassroomMember>, String>(
      (ref, classroomId) => ClassroomService.instance.getStudents(classroomId),
    );

/// Assigned content for a classroom.
final classroomContentProvider =
    FutureProvider.family<List<ClassroomContent>, String>(
      (ref, classroomId) =>
          ClassroomService.instance.getAssignedContent(classroomId),
    );
