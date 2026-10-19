/// One option from the public academic reference endpoints
/// (`/api/academic/units`, `/api/academic/sessions`).
///
/// The server returns both language forms for every row and the client picks
/// the one matching its locale ([labelFor]) — the server never picks a
/// language. [value] is the canonical string earlier app versions stored
/// verbatim (the Bengali unit name, or the English session range); it is used
/// only to recognise a value the profile already holds. The row [id] is what
/// gets submitted back as the foreign key.
///
/// Hand-written JSON parsing rather than `json_serializable`: this model is
/// read straight off the wire in the registration flow and must not depend on
/// a code-gen step.
class AcademicReferenceOption {
  const AcademicReferenceOption({
    required this.id,
    required this.value,
    required this.labelBn,
    required this.labelEn,
    this.type,
    this.sortOrder = 0,
    this.active = true,
  });

  /// Row id — the FK the registration payloads submit.
  final int id;

  /// Canonical stored string (Bengali unit name / English session range).
  final String value;

  final String labelBn;
  final String labelEn;

  /// `DEPARTMENT` or `OFFICE`; `null` for sessions.
  final String? type;

  final int sortOrder;

  /// Always `true` on the public pickers (they only list active rows).
  final bool active;

  bool get isDepartment => type == 'DEPARTMENT';

  /// The label for [languageCode] (`bn` / `en`).
  ///
  /// Bengali is the fallback, so an unexpected or missing code still renders
  /// the app's source language instead of the raw id.
  String labelFor(String languageCode) =>
      languageCode.startsWith('en') ? labelEn : labelBn;

  factory AcademicReferenceOption.fromJson(Map<String, dynamic> json) {
    return AcademicReferenceOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      value: json['value'] as String? ?? '',
      labelBn: json['labelBn'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      type: json['type'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'AcademicReferenceOption(id: $id, type: $type, labelBn: $labelBn)';
}
