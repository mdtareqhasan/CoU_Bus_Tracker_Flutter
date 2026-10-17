import '../../l10n/generated/app_localizations.dart';

/// One academic session offered in the registration pickers.
///
/// [value] is what gets submitted and stored — the English form
/// (`2020-2021`), which is what the backend's session regex expects and what
/// earlier app versions already sent. [label] renders it in the app's
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

/// Every canonical session value, for membership checks.
final Set<String> sessionValues = {for (final o in sessionOptions) o.value};

/// The localized label for a stored session value. An unknown value (e.g. one
/// stored outside this list) is shown as-is.
String sessionLabelFor(String value, AppLocalizations l10n) {
  for (final option in sessionOptions) {
    if (option.value == value) return option.label(l10n);
  }
  return value;
}
