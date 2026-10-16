# Localization (l10n)

How user-facing text works in this app. Read before adding or changing any
UI string.

## TL;DR

```dart
// 1. Widget with a BuildContext → use the extension
Text(context.l10n.homeStatActiveBuses)

// 2. No BuildContext (repository / provider / model / service) → use the global
return Failure(message: L10n.current.errorDefault);

// 3. Never compare or branch on display text — it changes with the language.
```

Then run:

```bash
flutter gen-l10n   # regenerate lib/l10n/generated/
flutter analyze
flutter test test/l10n_test.dart
```

## How it works

| Piece | File |
|---|---|
| Config (template locale, output dir) | `l10n.yaml` |
| Bengali strings (**template** — every key must exist here) | `lib/l10n/app_bn.arb` |
| English strings (translations) | `lib/l10n/app_en.arb` |
| Generated classes (`AppLocalizations`, per-locale files) | `lib/l10n/generated/` — **do not edit by hand** |
| `context.l10n` extension + `L10n.current` global | `lib/l10n/l10n.dart` |
| Active locale, persisted (`language_code` key) | `lib/app/locale_provider.dart` |
| Wired into the app | `lib/app/app.dart` (`locale:`, `localizationsDelegates`) |
| Tests | `test/l10n_test.dart` |

- **Template = `bn`.** Bengali is the app's source copy: if a key is missing
  from `app_en.arb`, the app shows the Bengali text and
  `lib/l10n/untranslated_messages.json` (gitignored) lists the gap. Treat any
  entry there as an open task.
- `pubspec.yaml` has `generate: true`, so `flutter run` / `flutter build`
  regenerate the classes automatically. Run `flutter gen-l10n` manually after
  editing ARB files when you only run `flutter analyze` / `flutter test`.

## Adding a string

1. Add the key to **both** ARB files (`app_bn.arb` and `app_en.arb`), with a
   `@key` `description` when the meaning isn't obvious from the text alone.
2. `flutter gen-l10n`.
3. Use `context.l10n.key` (or `L10n.current.key` without a context).

### Key naming

`camelCase`, prefixed by the area it belongs to, so related keys sort
together:

- `navHome`, `navBuses` — bottom navigation
- `homeStatActiveBuses`, `homeTodaySchedule` — home screen
- `profileLogout`, `profileIdCard` — profile screen
- `authVerifyPhoneFirst`… — auth flow
- `error*` — everything from `core/error_handler.dart`
- Unprefixed keys are app-wide shared copy (`sessionExpiredMessage`).

Display strings owned by a helper class keep the helper's vocabulary
(`ErrorHandler.defaultError` reads `L10n.current.errorDefault`), so the mapping
stays guessable.

### Parameters and plurals (ICU syntax)

```jsonc
// app_bn.arb
"homeActiveBusCount": "{count} টি বাস সক্রিয় আছে",
"@homeActiveBusCount": {
  "description": "Home header, number of buses currently active",
  "placeholders": { "count": { "type": "num" } }
}

// app_en.arb
"homeActiveBusCount": "{count} buses are active"
```

Use `plural`/`select` when a language needs it:

```jsonc
"schedBusCount": "{count, plural, =0{No buses} one{1 bus} other{{count} buses}}"
```

Single quotes and braces are ICU syntax: write a literal `'` as `''`, and
avoid `{`/`}` in prose.

### Dates, numbers, times

```dart
DateFormat.yMMMd(L10n.locale).format(date)   // locale-aware date
NumberFormat.decimalPattern(L10n.locale).format(n)
```

Digit scripts and time-of-day words belong to `core/utils/time_utils.dart`,
which is context-free and therefore reads `L10n.*` (not `context.l10n`).

## Rules

1. **Display text is never an identifier.** No `if (label == 'সক্রিয় বাস')`,
   no `message.contains('মেয়াদ')` on our own strings. Use an id, route, enum
   or status code, and localize only at the point of display. See
   `home_screen.dart`'s stats grid for the pattern (a `'route'` key drives
   navigation; `'label'` is display-only).
2. **Logic runs on locale-independent input.** Backend error text (English),
   HTTP status codes and markers like `PROFILE_INCOMPLETE` are fine to match
   on. When a check must recognize our own localized text, use
   `ErrorHandler.isOtpExpired(message)` and friends — they compare against
   *every* supported locale, so they survive a language switch between the
   message being built and being checked.
3. **Context-free code uses `L10n.current`.** It is updated by
   `LocaleController` whenever the locale changes, so strings created outside
   the widget tree always match the UI.
4. **Strings are created in the language that is active at that moment.**
   Error messages stored in provider state are not re-translated later; they
   refresh on the next operation. That is intentional — keep error flows
   short-lived.
5. **Both ARBs in one change.** Never commit a key in only one file; the
   untranslated report is a checkpoint, not a backlog.

## Changing the language at runtime

`LocaleController.setLanguageCode('en')` (from `localeProvider`) updates
`MaterialApp.locale` and `L10n.current` instantly — no restart — and persists
the choice through `StorageService`. First launch follows the device language
(English system → English, otherwise Bengali); from then on the saved choice
always wins. The switcher UI lives in
`lib/features/profile/language_settings_card.dart` and is shown on Profile in
both the logged-in and logged-out states.

`supportedLocales` is generated from the ARB filenames (`bn`, `en`), so adding
a locale = add `app_<code>.arb`, translate, regenerate.

## Push notifications

In-app copy is covered above. FCM `title`/`body` currently arrive prebuilt
from the backend in one language; localizing those is a separate, cross-stack
task (send a key + params and render client-side in `core/services/
notification_service.dart`, or send both languages). Not covered by this doc.
