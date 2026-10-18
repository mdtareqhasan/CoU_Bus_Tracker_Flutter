import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/fcm_token_service.dart';
import '../features/providers.dart';
import '../l10n/l10n.dart';

/// Holds the user-selected app locale, persisted via [StorageService]'s
/// existing `language_code` key.
///
/// `MaterialApp` watches this as its `locale:`, so calling
/// [LocaleController.setLanguageCode] switches the whole app's language at
/// runtime — no restart. It also updates `L10n.current` so strings created
/// outside the widget tree (errors, model helpers) match the new language.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    // First launch (no saved choice): Bengali regardless of the system
    // language — this is a Comilla University app, so the default experience
    // is Bangla even on an English/Hindi/French phone. An explicit choice
    // always wins: a user who tapped EN keeps English across restarts.
    final code = ref.read(storageServiceProvider).getStoredLanguageCode() ?? 'bn';
    final locale = Locale(code);
    L10n.activate(locale);
    return locale;
  }

  /// Changes the active language and persists the choice.
  Future<void> setLanguageCode(String code) async {
    state = Locale(code);
    L10n.activate(state);
    await ref.read(storageServiceProvider).setLanguageCode(code);
    // Push notifications are localized server-side using the language the
    // device registered with, so re-register to keep it in sync. Best-effort:
    // [FcmTokenService] never throws, and the upsert is idempotent.
    await ref.read(fcmTokenServiceProvider).registerIfAuthenticated();
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
