import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Access to localized strings.
///
/// 1. **Widgets (anything with a `BuildContext`)** use the extension:
///
/// ```dart
/// Text(context.l10n.sessionExpiredMessage)
/// ```
///
/// 2. **Code without a `BuildContext`** (repositories, providers, models,
///    services) uses [L10n.current]:
///
/// ```dart
/// return Failure(message: L10n.current.networkMessage);
/// ```
///
/// [L10n.current] is kept in sync with the active locale by
/// `LocaleController` (see `lib/app/locale_provider.dart`), so it always
/// matches what the UI is showing.
///
/// **Never** compare or branch on these display strings — logic must key off
/// stable identifiers (enums, status codes, backend markers), because the
/// text changes with the language.
extension L10nLocalization on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localization lookup for code that runs outside the widget tree.
class L10n {
  L10n._();

  static Locale? _locale;
  static AppLocalizations? _instance;

  /// The currently active locale. Defaults to Bengali before the first frame.
  static Locale get locale => _locale ?? const Locale('bn');

  /// The active localizations instance.
  ///
  /// Falls back to Bengali if [activate] has not run yet, so context-free
  /// code can never throw during startup.
  static AppLocalizations get current {
    final cached = _instance;
    if (cached != null) return cached;
    return activate(const Locale('bn'));
  }

  /// Switches the cached lookup to [locale] and returns it.
  ///
  /// Called by `LocaleController` on startup and whenever the user changes
  /// language, so error messages built outside the widget tree are created
  /// in the same language the UI is showing.
  static AppLocalizations activate(Locale locale) {
    final isSupported = AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
    final effective = isSupported ? locale : const Locale('bn');
    final l10n = lookupAppLocalizations(effective);
    _locale = effective;
    _instance = l10n;
    return l10n;
  }
}
