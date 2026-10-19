import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error_handler.dart';
import '../../core/result.dart';
import '../../shared/models/academic_reference_option.dart';
import '../providers.dart';

/// The department/office/session options the registration pickers render.
///
/// Fetched from the public `/api/academic/**` reference endpoints and cached
/// for the lifetime of the app, so a user who reaches the completion screen
/// (or any future picker) pays for the two requests once.
class AcademicOptions {
  const AcademicOptions({required this.units, required this.sessions});

  /// All active units — departments first, then offices.
  final List<AcademicReferenceOption> units;

  /// All active academic sessions.
  final List<AcademicReferenceOption> sessions;

  /// What the unit picker offers for [role]: students choose a teaching
  /// department, teachers choose a department *or* an administrative office.
  ///
  /// [role] is case-insensitive; anything that is not `teacher` is a student.
  List<AcademicReferenceOption> unitsForRole(String? role) {
    if (role != null && role.trim().toLowerCase() == 'teacher') return units;
    return [
      for (final unit in units)
        if (unit.isDepartment) unit,
    ];
  }
}

/// Thrown when the reference lists could not be loaded. [message] is already
/// localized (built by `ErrorHandler`), so the UI can show it verbatim.
class AcademicOptionsException implements Exception {
  const AcademicOptionsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Both lists in parallel; registration needs units and (for students)
/// sessions, so one provider keeps a single loading/error/retry story on the
/// completion screen.
final academicOptionsProvider = FutureProvider<AcademicOptions>((ref) async {
  final repository = ref.watch(academicReferenceRepositoryProvider);
  final results = await Future.wait([
    repository.getUnits(),
    repository.getSessions(),
  ]);

  return AcademicOptions(
    units: _dataOrThrow(results[0]),
    sessions: _dataOrThrow(results[1]),
  );
});

List<AcademicReferenceOption> _dataOrThrow(
  Result<List<AcademicReferenceOption>> result,
) {
  switch (result) {
    case Success(data: final data):
      return data;
    case Failure(:final message):
      throw AcademicOptionsException(message);
    case Loading():
    case Empty():
      // Neither is ever produced by the repository — kept only so the switch
      // stays exhaustive if that changes.
      throw AcademicOptionsException(ErrorHandler.defaultError);
  }
}
