import '../../l10n/generated/app_localizations.dart';

/// One session in the bundled label table.
///
/// The registration pickers themselves are filled from the public
/// `/api/academic/sessions` endpoint and submit row ids; this table only maps
/// a *stored* value to its localized label. It is used to render
/// already-saved profiles and the completion form's locked field while the
/// fetched list is still in flight. [label] renders it in the app's language
/// (Bengali uses Bengali digits: ২০২০-২০২১).
///
/// The profile payload returns the Bengali display form — `name_bn`, e.g.
/// `২০২০-২০২১`, exactly like `department` — so that is [valueBn]. The same
/// range also exists in ASCII (`name_en`, `2020-2021`) and is accepted as
/// [valueEn], because older app versions stored it verbatim and payloads
/// already in memory may still carry it.
class SessionOption {
  const SessionOption(this.valueBn, this.valueEn, this.label);

  /// Bengali digits, as the profile response sends them.
  final String valueBn;

  /// ASCII range older payloads/rows may still hold.
  final String valueEn;

  final String Function(AppLocalizations l10n) label;
}

final List<SessionOption> sessionOptions = [
  SessionOption('২০১৬-২০১৭', '2016-2017', (l10n) => l10n.session2016),
  SessionOption('২০১৭-২০১৮', '2017-2018', (l10n) => l10n.session2017),
  SessionOption('২০১৮-২০১৯', '2018-2019', (l10n) => l10n.session2018),
  SessionOption('২০১৯-২০২০', '2019-2020', (l10n) => l10n.session2019),
  SessionOption('২০২০-২০২১', '2020-2021', (l10n) => l10n.session2020),
  SessionOption('২০২১-২০২২', '2021-2022', (l10n) => l10n.session2021),
  SessionOption('২০২২-২০২৩', '2022-2023', (l10n) => l10n.session2022),
  SessionOption('২০২৩-২০২৪', '2023-2024', (l10n) => l10n.session2023),
  SessionOption('২০২৪-২০২৫', '2024-2025', (l10n) => l10n.session2024),
  SessionOption('২০২৫-২০২৬', '2025-2026', (l10n) => l10n.session2025),
];

/// The localized label for a stored session value, in either language form.
/// An unknown value (e.g. one stored outside this list) is shown as-is.
String sessionLabelFor(String value, AppLocalizations l10n) {
  for (final option in sessionOptions) {
    if (option.valueBn == value || option.valueEn == value) {
      return option.label(l10n);
    }
  }
  return value;
}
