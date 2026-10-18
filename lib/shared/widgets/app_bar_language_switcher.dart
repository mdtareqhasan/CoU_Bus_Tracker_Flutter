import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale_provider.dart';
import '../../app/theme.dart';

/// Compact বাং/EN language toggle shown as the first element of a pre-login
/// screen's content, in the top-right corner — deliberately kept out of the
/// app bar and off the gradient header ribbon.
///
/// Styled for the light content background ([AppTheme.backgroundLight]): the
/// active segment is a filled blue pill with white text and the inactive one
/// is plain gray text, so both options stay clearly legible. (It used to sit
/// on the blue bar, where it needed white text for the inactive option — that
/// would be near-invisible on the light content.)
///
/// Tapping a segment calls [LocaleController.setLanguageCode], which re-renders
/// the whole app immediately (no restart) and persists the choice — so a user
/// who switches to English here still gets English next launch, and the
/// "default to Bangla" rule only applies while they have never picked.
///
/// For a full labeled list (the Profile screen) see `LanguageSettingsCard`.
class AppBarLanguageSwitcher extends ConsumerWidget {
  const AppBarLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(localeProvider).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'বাং',
            selected: currentCode == 'bn',
            onTap: () => _select(ref, 'bn'),
          ),
          const SizedBox(width: 2),
          _Segment(
            label: 'EN',
            selected: currentCode == 'en',
            onTap: () => _select(ref, 'en'),
          ),
        ],
      ),
    );
  }

  void _select(WidgetRef ref, String code) {
    // No-op when already active, so a stray tap can't rewrite storage.
    if (ref.read(localeProvider).languageCode == code) return;
    ref.read(localeProvider.notifier).setLanguageCode(code);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space4,
        ),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
