import 'package:json_annotation/json_annotation.dart';

part 'notice.g.dart';

@JsonSerializable()
class Notice {
  final int? id;
  final String? title;
  final String? body;

  /// Who the notice targets: `STUDENT`, `TEACHER` or `ALL`. The backend
  /// already filters `/notices/active` by the caller's audience; this is kept
  /// on the model so the UI can badge it and so the client can re-check the
  /// stale-cache case (see [visibleToRole]).
  final String? audience;

  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const Notice({
    this.id,
    this.title,
    this.body,
    this.audience,
    this.isActive,
    this.createdAt,
    this.expiresAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeToJson(this);

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  /// Whether this notice may be shown to [role] (`'student'` / `'teacher'`,
  /// as stored by [StorageService]).
  ///
  /// The backend filters server-side, so this is a second line of defence
  /// only — it exists because the offline notice cache survives logout
  /// (`AuthNotifier.logout` clears the session but not the cache), meaning a
  /// student who signs in after a teacher on the same device could otherwise
  /// flash the teacher's cached notices until the network refresh lands.
  ///
  /// A notice with no audience (cached before the column existed) is treated
  /// as `ALL` — the same default the backend's migration applied.
  bool visibleToRole(String? role) {
    final target = audience?.trim().toUpperCase();
    if (target == null || target.isEmpty || target == 'ALL') return true;
    final mine = role == 'teacher' ? 'TEACHER' : 'STUDENT';
    return target == mine;
  }
}
