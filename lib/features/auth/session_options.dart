import '../../l10n/generated/app_localizations.dart';

/// One session in the bundled label table.
///
/// The registration pickers themselves are filled from the public
/// `/api/academic/sessions` endpoint and submit row ids; this table only maps
/// a *stored* value (the English form — `2020-2021`, what the backend expects
/// and what earlier app versions sent) to its localized label. It is used to
/// render already-saved profiles and the completion form's locked field while
/// the fetched list is still in flight. [label] renders it in the app's
/// language (Bengali uses Bengali digits: ২০২০-২০২১).
class SessionOption {
  const SessionOption(this.value, this.label);

  final String value;
  final String Function(AppLocalizations l10n) label;
}

final List<SessionOption> sessionOptions = [
  SessionOption('2016-2017', (l10n) => l10n.session2016),
  SessionOption('2017-2018', (l10n) => l10n.session2017),
  SessionOption('2018-2019', (l10n) => l10n.session2018),
  SessionOption('2019-2020', (l10n) => l10n.session2019),
  SessionOption('2020-2021', (l10n) => l10n.session2020),
  SessionOption('2021-2022', (l10n) => l10n.session2021),
  SessionOption('2022-2023', (l10n) => l10n.session2022),
  SessionOption('2023-2024', (l10n) => l10n.session2023),
  SessionOption('2024-2025', (l10n) => l10n.session2024),
  SessionOption('2025-2026', (l10n) => l10n.session2025),
];

/// The localized label for a stored session value. An unknown value (e.g. one
/// stored outside this list) is shown as-is.
String sessionLabelFor(String value, AppLocalizations l10n) {
  for (final option in sessionOptions) {
    if (option.value == value) return option.label(l10n);
  }
  return value;
}
